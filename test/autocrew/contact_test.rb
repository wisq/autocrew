require 'minitest_helper'
require 'autocrew/contact'
require 'autocrew/ownship'
require 'json'

module Autocrew
  class ContactTest < Minitest::Test
    test "glomp and unglomp" do
      contact = Contact.new
      contact.origin = Coord.new(45.6,78.9)
      contact.course = 123
      contact.speed  = 12

      observer = OwnShip.new(GameTime.parse("10:30"))
      contact.observations << Contact::Observation.new(observer, time1 = GameTime.parse('00:00'), bearing1 = 123.0)
      contact.observations << Contact::Observation.new(observer, time2 = GameTime.parse('01:00'), bearing2 = 234.0)

      json = Glomp.glomp(contact)
      assert_match /"course":123,/, json
      assert_match /"speed":12,/, json

      contact = Glomp.unglomp(json)
      assert_equal 45.6, contact.origin.x
      assert_equal 78.9, contact.origin.y
      assert_equal 123, contact.course
      assert_equal 12, contact.speed

      assert_equal 2, contact.observations.count

      # FIXME test observer
      assert_equal time1,     contact.observations[0].game_time
      assert_equal bearing1,  contact.observations[0].bearing

      # FIXME test observer
      assert_equal time2,     contact.observations[1].game_time
      assert_equal bearing2,  contact.observations[1].bearing
    end

    test "can serialize to JSON without solution data" do
      contact = Glomp.unglomp(Glomp.glomp(Contact.new))

      assert_nil contact.origin
      assert_nil contact.course
      assert_nil contact.speed
    end

    test "TMA should use existing contact data if available" do
      skip "slow" if ENV['FAST_TESTS'] == '1'

      contact = Contact.new
      contact.origin = Coord.new(1,2)
      contact.course = 123
      contact.speed  = 12

      Solver::ConstrainedMinimizer.any_instance.expects(:minimize).with([
        1.0, 2.0, # origin
        0.838670567945424, -0.5446390350150271, # course in vector format
        12.0 # speed
      ], anything)
      contact.solve
    end

    test "TMA with two straight legs" do
      skip "slow" if ENV['FAST_TESTS'] == '1'

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
      assert stats2.iterations < 50, "second solve should be much faster"
    end

    test "TMA with two straight legs, far from zero origin" do
      skip "slow" if ENV['FAST_TESTS'] == '1'

      contact = Contact.new  # Travelling southeast at 5 knots
      ownship = mock  # 10 nmi north of contact, travelling east at 10 knots

      time1 = GameTime.parse('00:00')
      contact.observations << Contact::Observation.new(ownship, time1, 180.0)
      ownship.expects(:location).at_least_once.with(time1).returns(Coord.new(100, -190))

      time2 = GameTime.parse('00:30')
      contact.observations << Contact::Observation.new(ownship, time2, 195.3585832227504)
      ownship.expects(:location).at_least_once.with(time2).returns(Coord.new(105, -190))

      time3 = GameTime.parse('01:00')
      contact.observations << Contact::Observation.new(ownship, time3, 205.52877936550928)
      ownship.expects(:location).at_least_once.with(time3).returns(Coord.new(110, -190))

      # Change ownship to travel south at 10 knots:

      time4 = GameTime.parse('01:30')
      contact.observations << Contact::Observation.new(ownship, time4, 204.5055916764859)
      ownship.expects(:location).at_least_once.with(time4).returns(Coord.new(110, -195))

      time5 = GameTime.parse('02:00')
      contact.observations << Contact::Observation.new(ownship, time5, 202.5)
      ownship.expects(:location).at_least_once.with(time5).returns(Coord.new(110, -200))

      assert_nil contact.origin
      assert_nil contact.course
      assert_nil contact.speed

      stats1 = contact.solve
      assert_in_delta  100, contact.origin.x
      assert_in_delta -200, contact.origin.y
      assert_in_delta  135, contact.course
      assert_in_delta    5, contact.speed
      assert stats1.iterations > 50, "first solve is slow"

      stats2 = contact.solve
      assert_in_delta  100, contact.origin.x
      assert_in_delta -200, contact.origin.y
      assert_in_delta  135, contact.course
      assert_in_delta    5, contact.speed
      assert stats2.iterations < 50, "second solve should be much faster"
    end

    test "TMA with two observers" do
      skip "slow" if ENV['FAST_TESTS'] == '1'

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

      contact.course = 20 # This one needs a little help. :(

      stats1 = contact.solve
      assert_in_delta 0, contact.origin.x
      assert_in_delta 0, contact.origin.y
      assert_in_delta 45, contact.course
      assert_in_delta 6, contact.speed
      assert stats1.iterations > 50, "first solve is slow"

      stats2 = contact.solve
      assert_in_delta 0, contact.origin.x
      assert_in_delta 0, contact.origin.y
      assert_in_delta 45, contact.course
      assert_in_delta 6, contact.speed
      assert stats2.iterations < 50, "second solve should be much faster"
    end

    test "TMA with two straight legs, far offset from 00:00 hours" do
      skip "slow" if ENV['FAST_TESTS'] == '1'

      contact = Contact.new  # Travelling southeast at 5 knots
      ownship = mock  # 10 nmi north of contact, travelling east at 10 knots

      time1 = GameTime.parse('20:00')
      contact.observations << Contact::Observation.new(ownship, time1, 180.0)
      ownship.expects(:location).at_least_once.with(time1).returns(Coord.new(0, 10))

      time2 = GameTime.parse('20:30')
      contact.observations << Contact::Observation.new(ownship, time2, 195.3585832227504)
      ownship.expects(:location).at_least_once.with(time2).returns(Coord.new(5, 10))

      time3 = GameTime.parse('21:00')
      contact.observations << Contact::Observation.new(ownship, time3, 205.52877936550928)
      ownship.expects(:location).at_least_once.with(time3).returns(Coord.new(10, 10))

      # Change ownship to travel south at 10 knots:

      time4 = GameTime.parse('21:30')
      contact.observations << Contact::Observation.new(ownship, time4, 204.5055916764859)
      ownship.expects(:location).at_least_once.with(time4).returns(Coord.new(10, 5))

      time5 = GameTime.parse('22:00')
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
      assert stats2.iterations < 50, "second solve should be much faster"
    end
  end
end
