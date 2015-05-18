require 'minitest_helper'
require 'autocrew/coord'

module Autocrew
  class CoordTest < Minitest::Test
    test "create" do
      coord = Coord.new(10, -20)
      assert_equal  10.0, coord.x
      assert_equal -20.0, coord.y
    end

    test "degrees to radians" do
      assert_equal 0, Coord.deg2rad(0)
      assert_equal Math::PI / 4, Coord.deg2rad(45)
      assert_equal Math::PI, Coord.deg2rad(180)
      assert_equal Math::PI * 2, Coord.deg2rad(360)
    end

    test "travel north" do
      coord1 = Coord.new(-10, 10)
      coord2 = coord1.travel(0, 1)
      assert_equal -10.0, coord2.x
      assert_equal  11.0, coord2.y
    end

    test "travel east" do
      coord1 = Coord.new(10, 10)
      coord2 = coord1.travel(90, 2)
      assert_equal 12.0, coord2.x
      assert_equal 10.0, coord2.y
    end

    test "travel south" do
      coord1 = Coord.new(10, -10)
      coord2 = coord1.travel(180, 3)
      assert_equal  10.0, coord2.x
      assert_equal -13.0, coord2.y
    end

    test "travel west" do
      coord1 = Coord.new(10, 10)
      coord2 = coord1.travel(270, 4)
      assert_equal  6.0, coord2.x
      assert_equal 10.0, coord2.y
    end

    test "travel northeast" do
      coord1 = Coord.new(0, 0)
      coord2 = coord1.travel(45, 5)
      assert_in_delta 3.5355, coord2.x
      assert_in_delta 3.5355, coord2.y
    end

    test "travel bearing 355" do
      coord1 = Coord.new(0, 0)
      coord2 = coord1.travel(355, 90)
      assert_in_delta -7.8440168472892, coord2.x
      assert_in_delta 89.6575228282571, coord2.y
    end
  end
end
