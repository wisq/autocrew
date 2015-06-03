require 'minitest_helper'
require 'autocrew/ownship'
require 'autocrew/event'

module Autocrew
  class OwnshipTest < Minitest::Test
    def setup
      @ownship = Ownship.new

      @start = GameTime.parse("10:30")
      @ownship.add_event Event::Initial.new(@start, 90, 6)
      @ownship.add_event Event::BeginTurn.new(GameTime.parse("10:50"), :starboard)
      @ownship.add_event Event::EndTurn.new(GameTime.parse("10:51"), 180)
    end

    test "glomp and unglomp" do
      json = Glomp.glomp(@ownship)
      ownship = Glomp.unglomp(json)

      assert_equal 3, ownship.events.count
      assert_equal :starboard, ownship.events[1].direction
    end

    test "initial location is undefined" do
      assert_nil @ownship.location(GameTime.parse("00:00"))
    end

    test "initial_time returns first event" do
      assert_equal @start, @ownship.initial_time
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
      assert_coord 2.045015815807855, -0.01864616142890283, loc
    end

    test "location after 21 minutes is completed turn" do
      offset = GameTime.parse("00:21")
      loc = @ownship.location(@start + offset)
      assert_coord 2.063661977236755, -0.06366197723675433, loc
    end

    test "location after 10 hours 21 minutes is 60 nautical miles further south" do
      offset = GameTime.parse("10:21")
      loc = @ownship.location(@start + offset)
      assert_coord 2.063661977236755, -60.06366197723675433, loc
    end
  end
end
