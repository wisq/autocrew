require 'minitest_helper'
require 'autocrew/solver/range_error_function'

module Autocrew::Solver
  class RangeErrorFunctionTest < Minitest::Test
    include Autocrew

    ACCURACY = 1e-10

    def setup
      skip "spammy"
    end

    test "exact match at bearing 90" do
      contact = Contact.new
      observer = mock

      # Both ships are travelling south at 10 knots.  Contact is 10 nmi bearing 90 from observer.
      time1 = GameTime.parse('00:00')
      contact.observations << Contact::Observation.new(observer, time1, 90.0)
      observer.expects(:location).at_least_once.with(time1).returns(Coord.new(0, 0))

      time2 = GameTime.parse('00:30')
      contact.observations << Contact::Observation.new(observer, time2, 90.0)
      observer.expects(:location).at_least_once.with(time2).returns(Coord.new(0, -5))

      time3 = GameTime.parse('01:00')
      contact.observations << Contact::Observation.new(observer, time3, 90.0)
      observer.expects(:location).at_least_once.with(time3).returns(Coord.new(0, -10))

      function = RangeErrorFunction.new(contact)
      evaluate = function.evaluate(10.0, 0.0, 0.0, -1.0, 10.0)
      gradient = function.evaluate_gradient(10.0, 0.0, 0.0, -1.0, 10.0)

      assert_equal 5, gradient.count
      assert_in_delta 0.0, evaluate, ACCURACY
      (0..4).each { |i| assert_in_delta 0.0, gradient[i], ACCURACY, "gradient result #{gradient.inspect} is non-zero" }
    end

    test "bearing 90, different speeds" do
      contact = Contact.new
      observer = mock

      # Contact is travelling south at 5 knots, observer at 10 knots.  Contact is 10 nmi bearing 90 from observer.
      time1 = GameTime.parse('00:00')
      contact.observations << Contact::Observation.new(observer, time1, 90.0)
      observer.expects(:location).at_least_once.with(time1).returns(Coord.new(0, 0))

      time2 = GameTime.parse('00:30')
      contact.observations << Contact::Observation.new(observer, time2, 75.96375653207353)
      observer.expects(:location).at_least_once.with(time2).returns(Coord.new(0, -5))

      time3 = GameTime.parse('01:00')
      contact.observations << Contact::Observation.new(observer, time3, 63.43494882292201)
      observer.expects(:location).at_least_once.with(time3).returns(Coord.new(0, -10))

      function = RangeErrorFunction.new(contact)
      evaluate = function.evaluate(10.0, 0.0, 0.0, -1.0, 5.0)
      gradient = function.evaluate_gradient(10.0, 0.0, 0.0, -1.0, 5.0)

      assert_equal 5, gradient.count
      assert_in_delta 0.0, evaluate, ACCURACY
      (0..4).each { |i| assert_in_delta 0.0, gradient[i], ACCURACY, "gradient result #{gradient.inspect} is non-zero" }
    end

    test "different courses, multiple legs" do
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

      function = RangeErrorFunction.new(contact)
      vector   = Vector.bearing(135)
      evaluate = function.evaluate(0.0, 0.0, vector.x, vector.y, 5.0)
      gradient = function.evaluate_gradient(0.0, 0.0, vector.x, vector.y, 5.0)

      assert_equal 5, gradient.count
      assert_in_delta 0.0, evaluate, ACCURACY
      (0..4).each { |i| assert_in_delta 0.0, gradient[i], ACCURACY, "gradient result #{gradient.inspect} is non-zero" }
    end
  end
end
