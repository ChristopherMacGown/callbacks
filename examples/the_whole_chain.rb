require 'rubygems'
require 'callbacks'

class BlockCallbacks
  include Callbacks

  def some_method
    p "In Some Method"
    :some_method
  end

  before(:some_method) { p :before_some_method; true }
  after (:some_method) { p :after_some_method; true }
end

class MethodCallbacks
  include Callbacks

  def some_method
    p "In Some Method"
    :some_method
  end

  def before_some_method 
    p :before_some_method
    true
  end

  def after_some_method
    p :after_some_method
  end

  before :some_method, :before_some_method
  after :some_method,  :after_some_method
end

p BlockCallbacks.new.some_method
p MethodCallbacks.new.some_method
