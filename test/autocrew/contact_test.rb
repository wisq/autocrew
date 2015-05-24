require 'minitest_helper'
require 'autocrew/contact'

module Autocrew
  class ContactTest < Minitest::Test
    test "TMA with two straight legs" do
      contact = Contact.new  # Travelling southeast at 5 knots
      ownship = mock  # 10 nmi north of contact, travelling east at 10 knots

      time1 = GameTime.parse('00:00')
      contact.observations << Contact::Observation.new(ownship, time1, 180.0)
      ownship.expects(:location).at_least_once.with(time1).returns(Coord.new(0, 10))

      time2 = GameTime.parse('00:30')
      contact.observations << Contact::Observation.new(ownship, time2, 195.3585832227504)
      ownship.expects(:location).at_least_once.with(time2).returns(Coord.new(5, 10))

      time3 = GameTime.parse('01:00')
      contact.observations << Contact::Observation.new(ownship, time3, 205.52877936550928)
      ownship.expects(:location).at_least_once.with(time3).returns(Coord.new(10, 10))

      # Change ownship to travel south at 10 knots:

      time4 = GameTime.parse('01:30')
      contact.observations << Contact::Observation.new(ownship, time4, 204.5055916764859)
      ownship.expects(:location).at_least_once.with(time4).returns(Coord.new(10, 5))

      time5 = GameTime.parse('02:00')
      contact.observations << Contact::Observation.new(ownship, time5, 202.5)
      ownship.expects(:location).at_least_once.with(time5).returns(Coord.new(10, 0))

      assert_nil contact.origin
      assert_nil contact.course
      assert_nil contact.speed

      stats1 = contact.solve
      assert_in_delta 0, contact.origin.x
      assert_in_delta 0, contact.origin.y
      assert_in_delta 135, contact.course
      assert_in_delta 5, contact.speed
      assert stats1.iterations > 50, "first solve is slow"

      stats2 = contact.solve
      assert_in_delta 0, contact.origin.x
      assert_in_delta 0, contact.origin.y
      assert_in_delta 135, contact.course
      assert_in_delta 5, contact.speed
      assert stats2.iterations < 5, "second solve should be much faster"
    end
  end
end
