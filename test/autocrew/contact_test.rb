require 'minitest_helper'
require 'autocrew/contact'

module Autocrew
  class ContactTest < Minitest::Test
    test "TMA with two observers" do
      skip "may not be possible"

      contact = Contact.new  # Travelling northeast at 6 knots
      ship1 = mock  # 10 nmi north of contact, travelling east at 5 knots
      ship2 = mock  # 10 nmi south of contact, travelling west at 5 knots

      time1 = GameTime.parse('00:00')
      contact.observations << Contact::Observation.new(ship1, time1, 180.0)
      contact.observations << Contact::Observation.new(ship2, time1,   0.0)
      ship1.expects(:location).at_least_once.with(time1).returns(Coord.new(0,  10))
      ship2.expects(:location).at_least_once.with(time1).returns(Coord.new(0, -10))

      time2 = GameTime.parse('00:30')
      contact.observations << Contact::Observation.new(ship1, time2, 182.7517379443212)
      contact.observations << Contact::Observation.new(ship2, time2,  20.86962414851531)
      ship1.expects(:location).at_least_once.with(time2).returns(Coord.new( 2.5,  10))
      ship2.expects(:location).at_least_once.with(time2).returns(Coord.new(-2.5, -10))

      time3 = GameTime.parse('01:00')
      contact.observations << Contact::Observation.new(ship1, time3, 187.49401888493406)
      contact.observations << Contact::Observation.new(ship2, time3,  32.98121264223171)
      ship1.expects(:location).at_least_once.with(time3).returns(Coord.new( 5,  10))
      ship2.expects(:location).at_least_once.with(time3).returns(Coord.new(-5, -10))

      contact.solve
    end

    test "TMA with two straight legs" do
      skip "wait a bit"

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

      contact.solve
    end
  end
end
