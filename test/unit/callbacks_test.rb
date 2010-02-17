require File.join(File.dirname(__FILE__), '../test_helper.rb')

class CallbackTest < Test::Unit::TestCase
  context "A Class" do
    should "raise for a callback on a non-existent method" do
      exception = assert_raises Callbacks::CallbackError do
        class FailClass
          include Callbacks

          before :some_method do |me, args|
            # stuff
          end
        end
      end
      assert_equal "No such method", exception.message
    end

    should "not raise when creating a callback with a block" do
      assert_nothing_raised do 
        class ExtantClass 
          include Callbacks
          
          def some_method
            :some_method
          end

          before :some_method do 
            # stuff
          end
        end
      end
    end

    context "A class with valid method names and callbacks" do
      context "When the callback backed method is called" do 
        setup do
          class ExtantClass
            include Callbacks

            def some_method
              :some_method
            end

            before :some_method do
              #stuff
              true
            end
          end

          @extant = ExtantClass.new
        end

        should "call the entire some_method callback chain" do
          @extant.expects(:callback).with(:some_method, :before).returns([true])
          @extant.expects(:callback).with(:some_method, :after).returns([true])
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

            before :some_method do 
              #stuff
              false
            end
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

            before :some_method do 
              #stuff
              false
            end
          end
        end

        should "not call the chained_method, or the after callbacks" do
          @extant = YA2ExtantClass.new
          @extant.expects(:callback).with(:some_method, :before).returns([false])
          @extant.expects(:callback).with(:some_method, :after).never
          @extant.some_method
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

      before :foo do |object, i, j, k|
        i * j * k
      end
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

        before :foo do 
          #stuff

          true
        end

        after :foo do
          :something
        end
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
      end

      class AChild < AParent
        before :foo do
          :something_else
        end

        after :foo do
          :yet_something_else
        end
      end

      class AnotherChild < AParent
        def bar
          :baz
        end

        before :foo, :bar
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
      end
    end
  end

  context "A parent with a subclass that redefines the callbacked method" do 
    should "rechain" do
      class A 
        include Callbacks

        def foo
          :foo
        end

        before :foo do 
          :before_foo
        end
      end

      # Hack to define B
      class B < A; end 
      B.expects(:chain)

      class B < A
        def foo
          :bar
        end
        chain :foo
      end

      assert_not_equal A.new.foo, B.new.foo
    end
  end
end
