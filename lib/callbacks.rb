# Callbacks
#
# Author:: Christopher MacGown (mailto:ignoti@gmail.com)
# Copyright:: Copyright © 2010 Christopher MacGown
# License:: MIT License
#
module Callbacks
  class CallbackError < StandardError; end

  def self.included(base)
    base.extend ClassMethods
  end

  # Execute callbacks on a callback chain
  def callback(method, type, *args)
    callbacks = self.class.callbacks[method][type]
    return true if callbacks.nil? or callbacks.empty?
    
    callbacks.map do |m|
      # No easy way to DRY this.
      if args.empty?
        m.is_a?(Proc) ? m.call(self) : send(m)
      else
        m.is_a?(Proc) ? m.call(self, *args) : send(m, *args)
      end
    end
  end

  # Yield the return value to a block and then return it
  def returning(value)
    yield value 
    value
  end

  module ClassMethods
    CALLBACK_TYPES = %w(before after outgoing incoming)

    # Define the callbacks, will raise CallbackError if the method doesn't exist
    # or the callback type is invalid
    # 
    # syntax:
    #  * before_somemethod
    #  * after_somemethod
    #  * outgoing_somemethod
    #  * incoming_somemethod
    #                  
    def define_callbacks(*callbacks)
      callbacks.each do |callback|
        callback.to_s =~ /(#{CALLBACK_TYPES.join("|")})_(.*?)/
        type, method = [$1, $']

        raise CallbackError, "Invalid Callback Type" unless CALLBACK_TYPES.include? type
        raise CallbackError, "No such method" unless method_defined? method.to_sym

        self.callbacks[method] ||= Hash.new([])

        # Setting a default automatically means ||= short-circuits and all callbacks
        # end up added to the default array instead. Makes for an interesting bug.
        self.callbacks[method][type] = [] if self.callbacks[method][type].empty?
        self.callbacks[method][type] << callback.to_sym

        class_eval <<-end_eval

          # implicitly define the default callback for the chain
          def #{callback}(*args)
            true
          end

          # Add a callback to the chain
          def self.#{callback}(*methods, &block)
            (methods << block).compact.each do |m|
              callbacks["#{method}"]["#{type}"] << m
            end
          end
        end_eval

        chain method.to_sym unless method_defined? :"chained_#{method}"
      end
    end

    alias :define_callback :define_callbacks
    
    # Create the callback chain
    def chain(method)
      before_types, after_types  = [%w(before outgoing), %w(after incoming)]

      class_eval <<-end_eval
        alias :"chained_#{method}" :"#{method}"

        def #{method}(*args)
          before = %w(before outgoing).map do |b| 
            callback "#{method}", b, *args
          end.flatten

          unless before.include? nil or before.include? false
            returning(args.empty? ? chained_#{method} : chained_#{method}(*args)) do |ret|
              if ret
                %w(after incoming).map do |a| 
                  callback "#{method}", a, *args
                end.flatten
              end
            end
          end
        end
      end_eval
    end

    # The included class's parent 
    def parent
      (self.ancestors[0, self.ancestors.index(Callbacks)] - [self]).first
    end

    # The included class's callbacks
    def callbacks
      deep_clone = lambda do |hash|
        hash.inject({}) do |h, (key, value)|
          h[key] = case value
                   when Hash: deep_clone.call(value)
                   when Array: value.clone
                   end
          h
        end
      end

      @@callbacks ||= {}
      # inner callback Array is the same, Hash needs a deep clone
      @@callbacks[self] ||= (parent ? deep_clone.call(@@callbacks[parent]) : {})
      @@callbacks[self]
    end
  end
end
