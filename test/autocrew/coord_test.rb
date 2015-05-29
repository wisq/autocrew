require 'minitest_helper'
require 'autocrew/coord'
require 'glomp'

module Autocrew
  class CoordTest < Minitest::Test
    test "create" do
      coord = Coord.new(10, -20)
      assert_equal  10.0, coord.x
      assert_equal -20.0, coord.y
    end

    test "glomp and unglomp" do
      json = Glomp.glomp(Coord.new(12.34, -56.78))
      assert_match /:12\.34\D/, json
      assert_match /:-56\.78\D/, json

      coord = Glomp.unglomp(json)
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
      assert_coord 3.5355, 3.5355, coord2
    end

    test "travel bearing 355" do
      coord1 = Coord.new(0, 0)
      coord2 = coord1.travel(355, 90)
      assert_coord -7.8440168472892, 89.6575228282571, coord2
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

    test "curved 10nmi port movement from 90 to 0" do
      coord = Coord.new(0, 0).travel_curved(:port, 90, 0, 10)
      assert_coord 6.36619, 6.36619, coord
    end

    test "curved 10nmi starboard movement from 90 to 180" do
      coord = Coord.new(0, 0).travel_curved(:starboard, 90, 180, 10)
      assert_coord 6.36619, -6.36619, coord
    end

    test "curved 5nmi starboard movement from 0 to 30" do
      coord = Coord.new(0, 0).travel_curved(:starboard, 0, 30, 5)
      assert_coord 1.2793631541868393, 4.774648292756861, coord
    end
  end
end
