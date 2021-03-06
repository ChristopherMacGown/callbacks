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

  private
  # Execute callbacks on a callback chain
  def callback(method, type, *args)
    callbacks = self.class.callbacks[method][type]
    return true if callbacks.nil? or callbacks.empty?

    callbacks.map do |m|
      m.is_a?(Proc) ? m.call(self, *args) : send(m, *args)
    end
  end

  # Yield the return value to a block and then return it
  def returning(value)
    yield value 
    value
  end

  module ClassMethods
    # Add a before callback to the a method
    #
    def before(method, *callback_methods, &block)
      build_callback :before, method, *callback_methods, &block
    end

    # Add an after callback to the a method
    def after(method, *callback_methods, &block)
      build_callback :after, method, *callback_methods, &block
    end


    # Creates a generic callback
    #
    # Raises CallbackError if the method does not exist
    #
    # Raises CallbackError if callback_methods is not empty AND block is not nil.
    #
    # Adds the callback_methods or block to the callback chain for method of the type 
    # specified. This method calls #chain on the passed method if the chained_method is
    # undefined
    #
    def build_callback(type, method, *callback_methods, &block)
      raise CallbackError, "No such method" unless method_defined? method.to_sym
      raise CallbackError, "Cannot specify block and method callbacks together" unless callback_methods.empty? or block.nil?

      self.callbacks[method] ||= Hash.new([])

      # Setting a default automatically means ||= short-circuits and all callbacks
      # end up added to the default array instead. Makes for an interesting bug.
      self.callbacks[method][type] = [] if self.callbacks[method][type].empty?

      (callback_methods << block).compact.each do |m|
        callbacks[method][type] << m
      end

      chain method.to_sym unless method_defined? :"chained_#{method}"
    end

    # Builds a chained method so the callbacks will fire.
    # This method must be called after a method chained in a parent class is
    # redefined in a subclass the callbacks should fire on the redefined
    # method
    def chain(method)
      before_types, after_types  = [%w(before outgoing), %w(after incoming)]

      # alias :chained_some_method :some_method
      #
      # def some_method(*args)
      #   before = callback "some_method", :before, *args
      #
      #   unless before.include? nil or before.include? false
      #     returning(chained_some_method(*args)) do |ret|
      #       callback "some_method", :after, *args if ret
      #     end
      #   end
      # end
      #           
      class_eval <<-end_eval
        alias :"chained_#{method}" :"#{method}"

        def #{method}(*args)
          before = callback "#{method}".to_sym, :before, *args

          unless before.include? nil or before.include? false
            returning(chained_#{method}(*args)) do |ret|
              callback "#{method}".to_sym, :after, *args if ret
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
      @@callbacks[self] ||= (@@callbacks[parent] ? deep_clone.call(@@callbacks[parent]) : {})
      @@callbacks[self]
    end
  end
end
