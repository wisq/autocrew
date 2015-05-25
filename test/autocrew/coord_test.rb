require 'minitest_helper'
require 'autocrew/coord'

module Autocrew
  class CoordTest < Minitest::Test
    test "create" do
      coord = Coord.new(10, -20)
      assert_equal  10.0, coord.x
      assert_equal -20.0, coord.y
    end

    test "serialize to json" do
      json = Coord.new(12.34, -56.78).to_json
      assert_match /:12\.34\D/, json
      assert_match /:-56\.78\D/, json

      coord = Coord.from_json(json)
      assert_equal  12.34, coord.x
      assert_equal -56.78, coord.y
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

    test "add two coords" do
      coord1 = Coord.new(10, 10)
      coord2 = Coord.new( 5, -5)
      coord = coord1 + coord2
      assert_equal 15, coord.x
      assert_equal  5, coord.y
    end

    test "compare two coords" do
      coord1 = Coord.new(10, 10)
      coord2 = Coord.new(10, 10)
      assert_equal coord1, coord2

      coord1 = Coord.new(10, 10)
      coord2 = Coord.new(10.0, 10.0)
      assert_equal coord1, coord2
    end
  end
end
