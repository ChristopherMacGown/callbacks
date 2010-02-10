require 'rubygems'
require 'callbacks'

class ALambdaCallback
  include Callbacks

  def some_method
    :some_method
  end

  define_callback :before_some_method
  before_some_method { p :before_some_method; true }
end

class ImplicitlyDefinedCallback 
  include Callbacks

  def some_method
    :some_method
  end

  define_callback :before_some_method

  def before_some_method
    p :before_some_method
    true
  end
end

class ExplicitlyDefinedCallback
  include Callbacks

  def some_method
    :some_method
  end

  def explicit_callback
    p :before_some_method
    true
  end

  define_callback :before_some_method
  before_some_method :explicit_callback
end

p ALambdaCallback.new.some_method
p ImplicitlyDefinedCallback.new.some_method
p ExplicitlyDefinedCallback.new.some_method

