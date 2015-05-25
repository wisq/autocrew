require 'minitest_helper'
require 'autocrew/ownship'
require 'autocrew/movement'

module Autocrew
  class OwnShipTest < Minitest::Test
    def setup
      @start = GameTime.parse("10:30")
      @ownship = OwnShip.new(@start)
      # Travel 6 knots due east for 20 minutes:
      @ownship.movements << Movement::Straight.new(GameTime.parse("00:20"), 90, 6)
      # Turn to starbeard, east (90) to south (180) over 1 minute, maintaining speed:
      @ownship.movements << Movement::Curved.new(GameTime.parse("00:01"), 90, :starboard, 180, 6)
      # Ongoing movement at 6 knots due south:
      @ownship.movements << Movement::Straight::Unbounded.new(180, 6)
    end

    test "glomp and unglomp" do
      # FIXME add movements
      json = Glomp.glomp(@ownship)
      ship = Glomp.unglomp(json)
    end

    test "initial location is undefined" do
      assert_nil @ownship.location(GameTime.parse("00:00"))
    end

    test "location at start is (0,0)" do
      loc = @ownship.location(@start)
      assert_in_delta 0.0, loc.x
      assert_in_delta 0.0, loc.y
    end

    test "location after 10 minutes is 1 nautical mile due east" do
      offset = GameTime.parse("00:10")
      loc = @ownship.location(@start + offset)
      assert_in_delta 1.0, loc.x
      assert_in_delta 0.0, loc.y
    end

    test "location after 20 minutes is 2 nautical miles due east" do
      offset = GameTime.parse("00:20")
      loc = @ownship.location(@start + offset)
      assert_in_delta 2.0, loc.x
      assert_in_delta 0.0, loc.y
    end

    test "location after 20.5 minutes is halfway into turn" do
      offset = GameTime.parse("00:20:30")
      loc = @ownship.location(@start + offset)
      assert_in_delta  2.0450158158078553, loc.x
      assert_in_delta -0.0186461614289027, loc.y
    end

    test "location after 21 minutes is completed turn" do
      offset = GameTime.parse("00:21")
      loc = @ownship.location(@start + offset)
      assert_in_delta  2.063661977236758, loc.x
      assert_in_delta -0.063661977236758, loc.y
    end

    test "location after 10 hours 21 minutes is 60 nautical miles further south" do
      offset = GameTime.parse("10:21")
      loc = @ownship.location(@start + offset)
      assert_in_delta   2.063661977236758, loc.x
      assert_in_delta -60.063661977236758, loc.y
    end
  end
end
