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
end

class AChildWithBlockCallbacks < AGenericParent
  before :some_method do
    p self.to_s + " inside before_some_method lambda"
    true 
  end

  after :some_method do
    p self.to_s + " inside after_some_method lambda"
    true 
  end
end

class AChildWithMethodCallbacks < AGenericParent
  def before_some_method
    p self.class.to_s + " inside :explicit_before"
    true 
  end

  def after_some_method
    p self.class.to_s + " inside :explicit_after"
    true 
  end

  before :some_method, :after_some_method
  after :some_method, :before_some_method
end

class AChildRedefinesChainedMethod < AGenericParent
  def some_method
    p self.class.to_s + " This method is different"
    :not_some_method
  end
  chain :some_method

  before :some_method do
    p "Callbacks still execute"
    :before_some_method
  end

  after :some_method do 
    p "Before and After"
    :after_some_method
  end
end

p AGenericParent
p AGenericParent.new.some_method
p AGenericParent.callbacks
puts "---"
p AChildWithBlockCallbacks
p AChildWithBlockCallbacks.new.some_method
p AChildWithBlockCallbacks.callbacks
puts "---"
p AChildWithMethodCallbacks
p AChildWithMethodCallbacks.new.some_method
p AChildWithMethodCallbacks.callbacks
puts "---"
p AChildRedefinesChainedMethod
p AChildRedefinesChainedMethod.new.some_method
p AChildRedefinesChainedMethod.callbacks
puts "---"
