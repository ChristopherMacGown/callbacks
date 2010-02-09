require File.join(File.dirname(__FILE__), '../test_helper.rb')

class CallbackTest < Test::Unit::TestCase
  context "A Class" do
    should "raise for an invalid callback type" do
      exception = assert_raises Callbacks::CallbackError do
        class FailClass
          include Callbacks

          define_callback :pants_some_method
        end
      end

      assert_equal "Invalid Callback Type", exception.message
    end

    should "raise for a callback on a non-existent method" do
      exception = assert_raises Callbacks::CallbackError do
        class FailClass
          include Callbacks

          define_callback :before_some_method
        end
      end
      assert_equal "No such method", exception.message
    end

    should "not raise when defining available callback chains on existent methods" do
      assert_nothing_raised do 
        class ExtantClass 
          include Callbacks
          
          def some_method
            :some_method
          end

          define_callback :before_some_method
        end
      end
    end

    context "A class with valid method names and callbacks" do
      should "not raise when creating a callback with a block" do
        assert_nothing_raised do
          class SomeExtantClass
            include Callbacks

            def some_method
              :some_method
            end

            define_callback :before_some_method
            before_some_method { true }
          end
        end
      end

      context "When the callback backed method is called" do 
        setup do
          class ExtantClass
            include Callbacks

            def some_method
              :some_method
            end

            define_callback :before_some_method
            before_some_method { true }
          end

          @extant = ExtantClass.new
        end

        should "call the entire some_method callback chain" do
          @extant.expects(:callback).with("some_method", "before").returns([true, true])
          @extant.expects(:callback).with("some_method", "after").returns([true, true])
          @extant.some_method
        end

        should "return the value of some_method when some_method is called" do
          assert_equal :some_method, @extant.some_method
        end
      end
    end

    context "A class with valid method names and callbacks that can fail" do
      context "when the callback backed method is called" do
        setup do
          class YAExtantClass
            include Callbacks

            def some_method
              :some_method
            end

            define_callback :before_some_method
            before_some_method { false }
          end
        end

        should "return nil" do
          assert_nil YAExtantClass.new.some_method
        end
      end

      context "same as above stupid teardowns" do
        setup do
          class YA2ExtantClass
            include Callbacks

            def some_method
              :some_method
            end

            define_callback :before_some_method
            before_some_method { false }
          end
        end

        should "not call the chained_method, or the after callbacks" do
          @this_extant = YA2ExtantClass.new
          @this_extant.expects(:callback).with("some_method", "before").returns([false])
          @this_extant.expects(:callback).with("some_method", "after").never
          @this_extent.expects(:chained_some_method).never
          @this_extant.some_method
        end
      end
    end
  end

  context "A Class with callback arguments" do
    class Foo
      include Callbacks

      def foo(a, b, c)
        a + b + c
      end

      define_callback :before_foo
      before_foo { |method, i,j,k| i * j * k }
    end

    should "return the sum of the three arguments" do
      assert_equal 6, Foo.new.foo(1,2,3)
    end
  end

  context "A Parent Class and a Single Child" do
    setup do
      class SomeParent
        include Callbacks

        def foo
          :foo
        end

        def callbacks
          self.class.callbacks
        end

        define_callbacks :before_foo, :after_foo
        before_foo { true }
        after_foo { :do_something }
      end

      class SomeChild < SomeParent; end
    end

    context "the child" do
      should "have the same callback chain and behaviour as the parent" do
        assert_equal SomeParent.new.callbacks, SomeChild.new.callbacks
        assert_equal SomeParent.new.foo, SomeChild.new.foo
      end
    end
  end

  context "A Parent Class and two Children" do
    setup do
      class AParent
        include Callbacks

        def foo
          :foo
        end

        def callbacks
          self.class.callbacks
        end

        define_callbacks :before_foo, :after_foo
      end
      class AChild < AParent
        before_foo { true }
        after_foo { p "BLAH"} 
      end

      class AnotherChild < AParent
        def before_foo
          :before_foo
        end

        def after_foo
          :after_foo
        end
      end
    end

    context "both children" do 
      should "have different callback chains" do
        assert_not_equal AChild.new.callbacks, AnotherChild.new.callbacks
      end

      context "when foo is called" do
        should "return :foo" do
          assert_equal :foo, AChild.new.foo
          assert_equal :foo, AnotherChild.new.foo
        end

        should "call before_foo as well as any proc callbacks in the chain" do
          @another_child = AnotherChild.new
          @another_child.expects(:send).with(:before_foo).returns(@another_child.before_foo)
          @another_child.callback("foo", "before")
        end
      end
    end
  end

  context "A class with an incoming callback" do
    should "not raise with the class definition" do
      class IncomingCallback
        include Callbacks

        def foo
          :bar
        end

        define_callback :incoming_foo
        incoming_foo { :bar }
      end

      IncomingCallback.new.foo
    end
  end
end
