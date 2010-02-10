require 'rubygems'
require 'callbacks'

class LambdaCallbacks
  include Callbacks

  def some_method
    p "In Some Method"
    :some_method
  end

  define_callbacks :before_some_method, :after_some_method

  before_some_method { p :before_some_method; true }
  after_some_method { p :after_some_method; true }
end

class ImplicitlyDefinedCallbacks
  include Callbacks

  def some_method
    p "In Some Method"
    :some_method
  end

  define_callbacks :before_some_method, :after_some_method

  def before_some_method
    p :before_some_method
    true
  end

  def before_some_method
    p :after_some_method
    true
  end
end

class ExplicitlyDefinedCallbacks
  include Callbacks

  def some_method
    p "In Some Method"
    :some_method
  end

  def explicit_before_callback
    p :before_some_method
    true
  end

  def explicit_after_callback
    p :after_some_method
    true
  end

  define_callbacks :before_some_method, :after_some_method
  before_some_method :explicit_before_callback
  after_some_method :explicit_after_callback
end

p LambdaCallbacks.new.some_method
p ImplicitlyDefinedCallbacks.new.some_method
p ExplicitlyDefinedCallbacks.new.some_method
