require 'minitest_helper'
require 'glomp/test_class'
require 'glomp/glomper'
require 'glomp/unglomper'

module Glomp
  class GlomperTest < Minitest::Test
    test "glomp and unglomp" do
      object1 = GlompTestClass.new({'foo' => 123, 'bar' => 987}, nil)
      object2 = GlompTestClass.new(345, object1)
      object3 = GlompTestClass.new([678, object2], nil)

      json = Glomper.new.glomp(object3)
      assert_match /:123\D/, json
      assert_match /:345\D/, json
      assert_match /:\[678,{/, json

      new_object3 = Unglomper.new.unglomp(json)
      assert_kind_of GlompTestClass, new_object3
      assert_equal 678, new_object3.value.first

      new_object2 = new_object3.value.last
      assert_kind_of GlompTestClass, new_object2
      assert_equal 345, new_object2.value

      new_object1 = new_object2.ref
      assert_kind_of GlompTestClass, new_object1
      assert_equal({'foo' => 123, 'bar' => 987}, new_object1.value)
    end

    test "glomp detects immediate circular references" do
      object = GlompTestClass.new(123, nil)
      object.ref = object

      assert_raises Glomper::CircularReferenceError do
        Glomper.new.glomp(object)
      end
    end

    test "glomp detects deeper circular references" do
      object1 = GlompTestClass.new(123, nil)
      object2 = GlompTestClass.new(345, object1)
      object1.ref = object2

      assert_raises Glomper::CircularReferenceError do
        Glomper.new.glomp(object1)
      end
    end

    test "glomp circular reference detection is not confused by #== equality" do
      object1 = GlompTestClass.new(123, nil)
      object2 = GlompTestClass.new(345, object1)
      object1.stubs(:==).returns(true)
      object2.stubs(:==).returns(true)

      json = Glomper.new.glomp(object2)
      assert_match /:123\D/, json
      assert_match /:345\D/, json
    end
  end
end
