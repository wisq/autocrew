require 'minitest_helper'
require 'autocrew/ownship'
require 'autocrew/event'

module Autocrew
  class OwnShipTest < Minitest::Test
    def setup
      @ownship = OwnShip.new

      @start = GameTime.parse("10:30")
      @ownship.add_event Event::Initial.new(@start, 90, 6)
      @ownship.add_event Event::BeginTurn.new(GameTime.parse("10:50"), :starboard)
      @ownship.add_event Event::EndTurn.new(GameTime.parse("10:51"), 180)
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
      assert_coord 0.0, 0.0, loc
    end

    test "location after 10 minutes is 1 nautical mile due east" do
      offset = GameTime.parse("00:10")
      loc = @ownship.location(@start + offset)
      assert_coord 1.0, 0.0, loc
    end

    test "location after 20 minutes is 2 nautical miles due east" do
      offset = GameTime.parse("00:20")
      loc = @ownship.location(@start + offset)
      assert_coord 2.0, 0.0, loc
    end

    test "location after 20.5 minutes is halfway into turn" do
      offset = GameTime.parse("00:20:30")
      loc = @ownship.location(@start + offset)
      assert_coord 2.031830988618379, -0.03183098861837894, loc
    end

    test "location after 21 minutes is completed turn" do
      offset = GameTime.parse("00:21")
      loc = @ownship.location(@start + offset)
      assert_coord 2.063661977236755, -0.06366197723675433, loc
    end

    test "location after 10 hours 21 minutes is 60 nautical miles further south" do
      offset = GameTime.parse("10:21")
      loc = @ownship.location(@start + offset)
      assert_coord 62.063661977236755, -0.06366197723675433, loc
    end
  end
end
