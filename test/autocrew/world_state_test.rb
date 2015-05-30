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
      # FIXME test stopwatch

      json = Glomp.glomp(state)
      state = Glomp.unglomp(json)

      assert_equal 90, state.ownship.events.first.course
      assert_equal 2, state.contacts.count
      assert_equal 12.3, state.contacts['s1'].origin.x
      assert_equal 78.9, state.contacts['s2'].origin.x
    end
  end
end
