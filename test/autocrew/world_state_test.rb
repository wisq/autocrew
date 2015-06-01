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
  end
end
