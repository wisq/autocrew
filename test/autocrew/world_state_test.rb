require 'minitest_helper'
require 'autocrew/world_state'

module Autocrew
  class WorldStateTest < Minitest::Test
    test "can save" do
      ownship = Ownship.new
      ownship.add_event Event::Initial.new(@start, 90, 6)

      contact1 = Contact.new
      contact1.origin = Coord.new(12.3, 45.6)

      contact2 = Contact.new
      contact2.origin = Coord.new(78.9, 1011.12)

      state = WorldState.new
      state.ownship = ownship
      state.contacts = {'s1' => contact1, 's2' => contact2}
      state.stopwatch = Stopwatch.new(game_time = GameTime.parse("00:30"), real_time = Time.now)

      json = Glomp.glomp(state)
      state = Glomp.unglomp(json)

      assert_equal 90, state.ownship.events.first.course
      assert_equal 2, state.contacts.count
      assert_equal 12.3, state.contacts['s1'].origin.x
      assert_equal 78.9, state.contacts['s2'].origin.x
      assert_equal game_time, state.stopwatch.game_time
      assert_equal real_time.to_f, state.stopwatch.real_time.to_f
    end

    test "points of interest with no time sync" do
      state = WorldState.new
      state.ownship = mock
      assert_equal [], state.display_points
    end

    test "points of interest with no ownship" do
      state = WorldState.new
      state.stopwatch = mock
      assert_equal [], state.display_points
    end

    test "points of interest with no focused contact" do
      state = WorldState.new
      state.ownship = ownship = mock
      state.stopwatch = stopwatch = mock

      time1 = GameTime.parse("13:37")
      coord1 = Coord.new(-5,-5)
      stopwatch.expects(:now).returns(time1)
      ownship.expects(:location).with(time1).returns(coord1)

      time2 = GameTime.parse("12:37")
      coord2 = Coord.new(5,5)
      ownship.expects(:location).with(time2).returns(coord2)

      points = state.display_points
      assert_equal [coord1, coord2], points.sort_by(&:x)
    end

    test "points of interest with a focused contact" do
      state = WorldState.new
      state.ownship = ownship = mock
      state.stopwatch = stopwatch = mock
      state.contacts = {'s1' => (contact = mock)}
      state.focus = 's1'

      # Assume both contact and ownship are travelling east at 10 knots.
      time1 = GameTime.parse("12:00")
      time2 = GameTime.parse("13:00")
      ownship_coord1 = Coord.new(-5,-5)
      ownship_coord2 = Coord.new( 5,-5)
      contact_coord1 = Coord.new(-5, 5)
      contact_coord2 = Coord.new( 5, 5)

      stopwatch.expects(:now).returns(time2)
      ownship.expects(:location).with(time1).returns(ownship_coord1)
      ownship.expects(:location).with(time2).returns(ownship_coord2)
      contact.expects(:location).with(time1).returns(contact_coord1)
      contact.expects(:location).with(time2).returns(contact_coord2)

      points = state.display_points
      assert_equal [
        ownship_coord1,
        ownship_coord2,
        contact_coord1,
        contact_coord2,
      ], points.sort_by { |c| [c.y, c.x] }
    end
  end
end
