module Callbacks
  class CallbackError < StandardError; end

  def self.included(base)
    base.extend ClassMethods
  end

  def callback(method, type, *args)
    callbacks = self.class.callbacks[method][type]
    return true if callbacks.nil? or callbacks.empty?
    
    callbacks.map do |m|
      if args.empty?
        m.is_a?(Proc) ? m.call(self) : send(m)
      else
        m.is_a?(Proc) ? m.call(self, *args) : send(m, *args)
      end
    end
  end

  def returning(value)
    yield value 
    value
  end

  module ClassMethods
    CALLBACK_TYPES = %w(before after outgoing incoming)

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
          def #{callback}(*args)
            true
          end

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
    
    def chain(method)
      before_types, after_types  = [%w(before outgoing), %w(after incoming)]

      class_eval <<-end_eval
        alias :"chained_#{method}" :"#{method}"
        def #{method}(*args)
          before = %w(before outgoing).map do |b| 
            callback "#{method}", b, *args
          end.flatten

          unless before.include? nil or before.include? false
            returning(args.empty? ? chained_#{method} : chained_#{method}(*args)) do 
              %w(after incoming).map do |a| 
                callback "#{method}", a, *args
              end.flatten
            end
          end
        end
      end_eval
    end

    def parent
      (self.ancestors[0, self.ancestors.index(Callbacks)] - [self]).first
    end

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
