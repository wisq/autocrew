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

    test "radians to degrees" do
      assert_equal 0,   Vector.rad2deg(0)
      assert_equal 45,  Vector.rad2deg(Math::PI / 4)
      assert_equal 180, Vector.rad2deg(Math::PI)
      assert_equal 360, Vector.rad2deg(Math::PI * 2)
    end

    test "create from bearing" do
      v = Vector.bearing(0)
      assert_in_delta 0.0, v.x
      assert_in_delta 1.0, v.y

      v = Vector.bearing(90)
      assert_in_delta 1.0, v.x
      assert_in_delta 0.0, v.y

      v = Vector.bearing(135)
      assert_in_delta  0.70710678118654752440084436210484903929, v.x
      assert_in_delta -0.70710678118654752440084436210484903928, v.y

      v = Vector.bearing(234)
      assert_in_delta -0.80901699437494742410229341718281905887, v.x
      assert_in_delta -0.58778525229247312916870595463907276859, v.y
    end

    test "convert to bearing" do
      v = Vector.new(0.0, 1.0)
      assert_in_delta 0.0, v.bearing

      v = Vector.new(1.0, 0.0)
      assert_in_delta 90.0, v.bearing

      v = Vector.new(0.70710678118654752440084436210484903929, -0.70710678118654752440084436210484903928)
      assert_in_delta 135.0, v.bearing

      v = Vector.new(-0.80901699437494742410229341718281905887, -0.58778525229247312916870595463907276859)
      assert_in_delta 234.0, v.bearing % 360.0
    end
  end
end
