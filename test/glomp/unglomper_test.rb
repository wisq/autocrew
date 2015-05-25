require 'minitest_helper'
require 'glomp/test_class'
require 'glomp/glomper'
require 'glomp/unglomper'

module Glomp
  class UnglomperTest < Minitest::Test

    test "unglomp detects immediate circular references" do
      object = GlompTestClass.new(123, nil)
      hash = JSON.load(Glomper.new.glomp(object))

      hash['objects']['1']['data']['ref'] = {'glomper_reference' => 1}
      json = hash.to_json

      assert_raises Unglomper::CircularReferenceError do
        Unglomper.new.unglomp(json)
      end
    end

    test "unglomp detects deeper circular references" do
      object1 = GlompTestClass.new(123, nil)
      object2 = GlompTestClass.new(345, object1)
      hash = JSON.load(Glomper.new.glomp(object2))

      data = hash['objects']['2']['data']
      assert_equal 123, data['value']  # make sure we have the right one
      data['ref'] = {'glomper_reference' => 2}
      json = hash.to_json

      assert_raises Unglomper::CircularReferenceError do
        Unglomper.new.unglomp(json)
      end
    end
  end
end
