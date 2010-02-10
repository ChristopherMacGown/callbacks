require 'rubygems'
require 'callbacks'

class AGenericParent
  include Callbacks

  def some_method
    p self.class.to_s + " Inside :some_method"
    :some_method
  end

  def callbacks
    # Execute me and note that each sub-class has a different
    # callback chain from AGenericParent and its siblings if 
    # it defines lambda or method callbacks.
    self.class.callbacks
  end

  define_callbacks :before_some_method, :after_some_method
end

class AChildWithLambdaCallbacks < AGenericParent
  before_some_method do
    p self.to_s + " inside before_some_method lambda"
    true 
  end

  after_some_method do
    p self.to_s + " inside after_some_method lambda"
    true 
  end
end

class AChildWithImplicitlyDefinedMethodCallbacks < AGenericParent
  def before_some_method
    p self.class.to_s + " inside :before_some_method method"
    true 
  end

  def after_some_method
    p self.class.to_s + " inside :after_some_method method"
    true 
  end
end

class AChildWithExplicitlyDefinedMethodCallbacks < AGenericParent
  def explicit_before
    p self.class.to_s + " inside :explicit_before"
    true 
  end

  def explicit_after
    p self.class.to_s + " inside :explicit_after"
    true 
  end


  before_some_method :explicit_before
  after_some_method :explicit_after
end

class AChildRedefinesChainedMethod < AGenericParent
  def some_method
    p self.class.to_s + " This method is different"
    :not_some_method
  end
  chain :some_method

  def before_some_method
    p "Callbacks still execute"
    :before_some_method
  end

  def after_some_method
    p "Before and After"
    :after_some_method
  end
end

p AGenericParent
p AGenericParent.new.some_method
p AGenericParent.callbacks
puts "---"
p AChildWithLambdaCallbacks
p AChildWithLambdaCallbacks.new.some_method
p AChildWithLambdaCallbacks.callbacks
puts "---"
p AChildWithImplicitlyDefinedMethodCallbacks
p AChildWithImplicitlyDefinedMethodCallbacks.new.some_method
p AChildWithImplicitlyDefinedMethodCallbacks.callbacks
puts "---"
p AChildWithExplicitlyDefinedMethodCallbacks
p AChildWithExplicitlyDefinedMethodCallbacks.new.some_method
p AChildWithExplicitlyDefinedMethodCallbacks.callbacks
puts "---"
p AChildRedefinesChainedMethod
p AChildRedefinesChainedMethod.new.some_method
p AChildRedefinesChainedMethod.callbacks
puts "---"
