require 'minitest_helper'
require 'adam_math/find_root'
require 'adam_math/differentiable_function'
require 'adam_math/root_bracket'

module AdamMath
  class FindRootTest < Minitest::Test
    # this is pretty close to the minimum that i can make it while still passing, given the original implementation. if an
    # implementation degrades substantially (with these functions, anyway), this should catch it
    ACCURACY = 1.77636e-15

    test "one-dimensional, double root" do
      # this is a simple parabola with a double root at x=1. because of the double root, which means the function never crosses zero, only
      # touches it, many methods have more trouble with it. in particular, only unbounded newton raphson is able to find it without having
      # the root at one of the interval boundaries
      function = DifferentiableFunction.new(
        lambda { |x| (x-1)*(x-1) },  # f(x) = (x-1)^2
        lambda { |x| 2*x-2 }
      )

      # test unbounded newton raphson with a wide interval
      assert_in_delta 1, FindRoot.unbounded_newton_raphson(function, RootBracket.new(-10, 10)), ACCURACY
      # the others need the root to be at one of the boundaries, although this is a trivial case for any method. make sure it works from
      # both edges for all methods
      assert_in_delta 1, FindRoot.bounded_newton_raphson(function, RootBracket.new(1, 10)), ACCURACY
      assert_in_delta 1, FindRoot.bounded_newton_raphson(function, RootBracket.new(-10, 1)), ACCURACY
      assert_in_delta 1, FindRoot.brent(function, RootBracket.new(1, 10)), ACCURACY
      assert_in_delta 1, FindRoot.brent(function, RootBracket.new(-10, 1)), ACCURACY
      assert_in_delta 1, FindRoot.subdivide(function, RootBracket.new(1, 10)), ACCURACY
      assert_in_delta 1, FindRoot.subdivide(function, RootBracket.new(-10, 1)), ACCURACY
    end

    test "one-dimensional, crosses zero" do
      # this is a parabola with roots at x=0 and x=2. since it crosses zero, it should be amenable to many different methods
      function = DifferentiableFunction.new(
        lambda { |x| (x-1)*(x-1) - 1 }, # f(x) = (x-1)^2 - 1
        lambda { |x| 2*x-2 }
      )

      # first, let's try some root bracketing
      interval = MutableRootBracket.new(0.5, 1.5)
      # bracket outwards
      assert FindRoot.bracket_outward(function, interval)
      assert interval.min <= 0 && interval.max >= 0 || interval.min <= 2 && interval.max >= 2  # make sure it brackets a root
      # bracket inwards. since interval, when divided into 20 pieces, will have the roots exactly on the boundaries, the sub intervals
      # should also (although that's not something we need to verify)
      interval = RootBracket.new(-10, 10)
      foundZero = foundTwo = false
      FindRoot.bracket_inward(function, interval, 20).each do |sub|
        foundZero = true if sub.min <= 0 && sub.max >= 0
        foundTwo  = true if sub.min <= 2 && sub.max >= 2
        assert sub.min <= 0 && sub.max >= 0 || sub.min <= 2 && sub.max >= 2
      end
      assert foundZero && foundTwo

      # try again, using an interval that doesn't divide evenly (and therefore won't provide cases that are trivial to solve)
      interval = RootBracket.new(-8, 9)
      foundZero = foundTwo = false;
      FindRoot.bracket_inward(function, interval, 20).each do |sub|
        root = -1
        if sub.min <= 0 && sub.max >= 0
          foundZero = true
          root = 0
        elsif sub.min <= 2 && sub.max >= 2
          foundTwo = true
          root = 2
        else
          assert false, "failed"
        end

        # ensure that all methods find the root
        assert_in_delta root, FindRoot.bounded_newton_raphson(function, sub), ACCURACY
        assert_in_delta root, FindRoot.brent(function, sub), ACCURACY
        assert_in_delta root, FindRoot.subdivide(function, sub), ACCURACY
        assert_in_delta root, FindRoot.unbounded_newton_raphson(function, sub), ACCURACY
      end
      assert foundZero && foundTwo
    end

    test "one-dimensional, no root" do
      # ensure that unbounded newton-raphson fails properly when there's no root
      function = DifferentiableFunction.new(
        lambda { |x| x*x+1 }, # f(x) = x^2+1, a parabola with no root
        lambda { |x| 2*x }
      )
      interval = RootBracket.new(-1, 1)
      assert_raises(FindRoot::RootNotFoundError) { FindRoot.unbounded_newton_raphson(function, interval) }
      # ensure that the others complain about the root not being bracketed
      assert_raises(FindRoot::RootNotBracketedError) { FindRoot.bounded_newton_raphson(function, interval) }
      assert_raises(FindRoot::RootNotBracketedError) { FindRoot.brent(function, interval) }
      assert_raises(FindRoot::RootNotBracketedError) { FindRoot.subdivide(function, interval) }
      # ensure that bracketing fails as it should
      assert !FindRoot.bracket_outward(function, interval)
      assert_equal 0, FindRoot.bracket_inward(function, RootBracket.new(-10, 10), 20).count
    end
  end
end
