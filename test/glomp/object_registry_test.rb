require 'minitest_helper'
require 'glomp/object_registry'

module Glomp
  class ObjectRegistryTest < Minitest::Test
    def setup
      @registry = ObjectRegistry.new
    end

    test "register and lookup" do
      assert_equal 1, @registry.register(obj1 = mock)
      assert_equal 2, @registry.register(obj2 = mock)
      assert_equal 3, @registry.register(obj3 = mock)
      assert_equal obj1, @registry.lookup(1)
      assert_equal obj2, @registry.lookup(2)
      assert_equal obj3, @registry.lookup(3)
    end

    test "register with explicit ID" do
      assert_equal 4, @registry.register(obj1 = mock, 4)
      assert_equal 5, @registry.register(obj2 = mock, 5)
      assert_equal 6, @registry.register(obj3 = mock, 6)
      assert_equal obj1, @registry.lookup(4)
      assert_equal obj2, @registry.lookup(5)
      assert_equal obj3, @registry.lookup(6)
    end

    test "register multiple times" do
      obj = mock
      assert_equal 1, @registry.register(obj)
      assert_equal 1, @registry.register(obj)
      assert_equal 1, @registry.register(obj, 1)
    end

    test "explicit/implicit ID collision" do
      assert_equal 1, @registry.register(mock, 1)

      assert_raises ObjectRegistry::RegisterCollisionError do
        @registry.register(mock, 1)
      end

      assert_raises ObjectRegistry::RegisterCollisionError do
        @registry.register(mock)
      end
    end

    test "multiple register attempt" do
      obj = mock
      assert_equal 1, @registry.register(obj)
      assert_raises ObjectRegistry::RegisterMismatchError do
        @registry.register(obj, 2)
      end
    end
  end
end
