require 'rubygems'
require 'callbacks'

class ABlockCallback
  include Callbacks

  def some_method
    :some_method
  end

  before :some_method do
    p :before_some_method
    :before_some_method
  end
end

class AMethodCallback
  include Callbacks

  def some_method
    :some_method
  end

  def method_callback 
    p :method_callback
    :method_callback
  end


  before :some_method, :method_callback
end

p ABlockCallback.new.some_method
p AMethodCallback.new.some_method

