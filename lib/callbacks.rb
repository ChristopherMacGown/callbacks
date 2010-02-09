module Callbacks
  class CallbackError < StandardError; end

  def self.included(base)
    base.extend ClassMethods
  end

  def callback(method, type, *args)
    return true unless self.class.callbacks[method][type]

    self.class.callbacks[method][type].map do |m|
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

        chain(method.to_sym, type) unless method_defined? :"chained_#{method}"
      end
    end

    alias :define_callback :define_callbacks
    
    def chain(method, type)
      before, after = case type
                      when /before|after/: %w(before after)
                      when /outgoing/:     %w(outgoing)
                      # special case, incoming callbacks operate on received data
                      when /incoming/: [nil, "incoming"]
                      end

      class_eval <<-end_eval
        alias :"chained_#{method}" :"#{method}"
        def #{method}(*args)
          before = callback "#{method}", "#{before}", *args

          unless before.include? nil or before.include? false
            returning(args.empty? ? chained_#{method} : chained_#{method}(*args)) do 
              callback "#{method}", "#{after}", *args
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
