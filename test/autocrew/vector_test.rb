require 'minitest_helper'
require 'autocrew/vector'

module Autocrew
  class VectorTest < Minitest::Test
    test "degrees to radians" do
      assert_equal 0, Vector.deg2rad(0)
      assert_equal Math::PI / 4, Vector.deg2rad(45)
      assert_equal Math::PI, Vector.deg2rad(180)
      assert_equal Math::PI * 2, Vector.deg2rad(360)
    end
  end
end
