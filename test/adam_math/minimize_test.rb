require 'minitest_helper'
require 'adam_math/minimize'
require 'adam_math/differentiable_function'
require 'adam_math/minimum_bracket'

module AdamMath
  class MinimizeTest < Minitest::Test
    ACCURACY = 1.5e-7

    test "one-dimensional" do
      # sin(x+1) + x/2 has local minima at -2/3PI-1, 4/3PI-1, 10/3PI-1, etc.
      function = DifferentiableFunction.new(
        lambda { |x| Math.sin(x+1) + x/2 },
        lambda { |x| Math.cos(x+1) + 0.5 }
      )
      nd_function = function.function  # create a version without derivative information
      # the three minima above are located between -5 and 13, so we should be able to find them with BracketInward()
      brackets = Minimize.bracket_inward(function, -5, 13, 3)
      assert_equal 3, brackets.count  # ensure we found them all
      # for each bracket, try to find it using all available methods
      minima = brackets.map do |bracket|
        x = Minimize.golden_section(function, bracket)  # first use golden section search, which is the most reliable
        assert_in_delta x, Minimize.brent(function, bracket), ACCURACY  # then make sure Brent's method gives a similar answer, both with
        assert_in_delta x, Minimize.brent(nd_function, bracket), ACCURACY  # and without the derivative
        x
      end
      minima.sort! # then sort the results to put them in a known order and make sure they're equal to the expected values
      assert_equal 3, minima.count
      assert_in_delta Math::PI*-2/3-1, minima[0], ACCURACY
      assert_in_delta Math::PI*4/3-1,  minima[1], ACCURACY
      assert_in_delta Math::PI*10/3-1, minima[2], ACCURACY

      # now test bracket_outward
      assert_raises RuntimeError do
        Minimize.bracket_outward(lambda { |x| x }, 0, 1)  # make sure it fails with functions that have no minimum
      end
      assert Minimize.bracket_outward(lambda { |x| 5 }, 0, 1)  # but succeeds with constant functions
      assert b1 = Minimize.bracket_outward(function, 0, 1)  # and with our sample function
      # make sure it searches in a downhill direction, as designed
      assert_in_delta Math::PI*-2/3-1, Minimize.golden_section(function, b1), ACCURACY
      assert b2 = Minimize.bracket_outward(function, 1, 2)
      assert_in_delta Math::PI*4/3-1, Minimize.golden_section(function, b2), ACCURACY

      # try a function with a singularity, for kicks
      nd_function = lambda { |x| Math.cos(x)/(x-1) }
      assert_in_delta 1, Minimize.golden_section(nd_function, MinimumBracket.new(-1, -0.1, 1)), ACCURACY
      assert_in_delta 1, Minimize.brent(nd_function, MinimumBracket.new(-1, -0.1, 1)), ACCURACY
    end

    test "multi-dimensional" do
      skip "broken"
      # test using the rosenbrock banana function, which has a long, curved, narrow valley
      function = RosenbrockBanana.new
      point = [-1.2, 2]
      value = Minimize.bfgs(function, point)
      assert_in_delta 1, point[0], 2.4e-10
      assert_in_delta 1, point[0], 2.4e-10
      assert_in_delta 0, value, 6.4e-20
    end
  end

  # Implements the Rosenbrock banana function f(x,y) = 100*(y-x^2)^2 + (1-x^2)^2.
  class RosenbrockBanana #< DifferentiableMDFunction
    def arity
      return 2
    end

    def call(a, b)
      aa = a*a
      return 100*(b-aa)*(b-aa) + (1-a)*(1-a)
    end

    def gradient(a, b)
      aa = a*a
      v = 200*(b-aa)
      return [2*((a-1) - v*a), v]
    end
  end
end
