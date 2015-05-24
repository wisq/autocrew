require 'matrix'
require 'autocrew'

module Autocrew::Solver
  # The smallest double-precision floating-point number that, when added to 1.0, produces a result not equal to 1.0.
  DOUBLE_PRECISION = 2.2204460492503131e-16
  # The square root of DOUBLE_PRECISION.
  SQRT_DOUBLE_PRECISION = 0.00000001490116119

  class DifferentiableFunction
    attr_reader :function

    def initialize(function, derivative)
      @function = function
      @derivative = derivative
    end

    def call(x)
      @function.call(x)
    end

    # Returns the value of the function's first derivative at the given point.
    def evaluate_derivative(x, derivs = 1)
      raise "derivs must be 1" unless derivs == 1
      @derivative.call(x)
    end

    def derivative_count
      1
    end
  end

  class MinimumBracket
    attr_reader :high1, :low, :high2

    def initialize(high1, low, high2)
      @high1 = high1
      @low   = low
      @high2 = high2
    end
  end

  class Minimize
    def self.bracket_inward(function, x1, x2, segments)
      raise "no function" unless function
      raise "segments must be positive" if segments <= 0

      x1 = x1.to_f
      x2 = x2.to_f

      segmentSize = (x2 - x1) / segments
      v1 = function.call(x1)
      origX2 = x2
      x2 = x1

      brackets = []
      (0...segments).each do |i|
        x2 = i == segments-1 ? origX2 : x2 + segmentSize  # make sure the end of the last segment exactly matches the original end
        # get the value of the function at the midpoint of the segment
        xm = x1 + (x2-x1)*0.5
        v2 = function.call(x2)
        vm = function.call(xm)

        # if the function doesn't appear to bracket a minimum based on the midpoint, fit a parabola to the three points and minimize that
        if vm >= v1 || vm >= v2
          # to fit a parabola to three points we first take the formula for a quadratic: A*x^2 + B*x + C = y. then we substitute for the
          # three (x,y) pairs and get three linear equations that we can solve for the coefficients A, B, and C. then we find the minimum or
          # maximum by solving for the point where the derivative (2A*x + B) equals zero, and we get x = -B/2A. note that this doesn't
          # depend on the value of C, so we needn't compute it. the straightforward solution gives:
          # d = (x1-x2) * (x1-x3) * (x2-x3)
          # A = (x1*(y3-y2) + x2*(y1-y3) + x3*(y2-y1)) / d
          # B = (x1^2*(y2-y3) + x2^2*(y3-y1) + x3^2*(y1-y2)) / d
          #
          # then -B / 2A = -((x1^2*(y2-y3) + x2^2*(y3-y1) + x3^2*(y1-y2)) / d) * (d / 2*(x1*(y3-y2) + x2*(y1-y3) + x3*(y2-y1)))
          # (multiplying by the reciprocal) and d cancels out. distributing the negation in the numerator leaves:
          # (x1^2*(y3-y2) + x2^2*(y1-y3) + x3^2*(y2-y1)) / (2*(x1*(y3-y2) + x2*(y1-y3) + x3*(y2-y1)))
          #
          # this equals (x1*g + x2*h + x3*j) / 2(g+h+j) if we take g=x1(y3-y2), h=x2(y1-y3), and j=x3(y2-y1). two final wrinkles: if A = 0,
          # then this would involve division by zero. in that case, the quadratic reduces to a linear form (B*x + C = y). in that
          # case, the line may have a minimum inside the subinterval (at an edge), but it likely continues beyond the subinterval, in
          # which case it's not really a minimum of the function. so we'll ignore the case where A = 0. also, it's possible that the minimum
          # of the parabola is outside the subinterval. in that case also, we'll ignore it.
          # note that in the following code (x1,xm,x2,v1,vm,v2) represent (x1,x2,x3,y1,y2,y3) in the math
          g = x1*(v2-vm)
          h = xm*(v1-v2)
          j = x2*(vm-v1)
          d = g + h + j

          if d != 0  # if we can fit a proper parabola to it...
            x = (x1*g + xm*h + x2*j) / (2*d)  # take the minimum or maximum of the parabola
            if (x1-x)*(x-x2) > 0  # if the minimum or maximum of the parabola is within the subinterval...
              xm = x # use that
              vm = function.call(xm) # and get the function value there
            end
          end
        end

        # if we found a minimum either way, return it
        if v1 > vm && v2 > vm
          brackets << MinimumBracket.new(x1, xm, x2)
        end

        x1 = x2
        v1 = v2
      end

      brackets
    end

    INV_GOLDEN_RATIO = 0.61803398874989485
    INV_GR_COMPLEMENT = 1 - INV_GOLDEN_RATIO

    def self.golden_section(function, bracket, tolerance = SQRT_DOUBLE_PRECISION)
      raise "no function" unless function
      raise "tolerance must not be negative" if tolerance < 0

      # the golden section search works is analogous to the bisection search for finding roots. it works by repeatedly shrinking the bracket
      # around the minimum until the bracket is very small. we maintain four points x0, x1, x2, and x3 where f(x0) >= f(x1) and
      # f(x3) >= f(x1) or f(x0) >= f(x2) and f(x3) >= f(x2). that is, x0 and x3 represent the edges of the bracket, x1 or x2 is the low
      # point in the bracket, and the other point is the new point we're evaluating at each step. so at each iteration, we have two high
      # points on the edges, and one low point and one point of unknown value in between: (H  L  U  H) or (H  U  L  H), stored in
      # (x0 x1 x2 x3). depending on the relationship between the low and unknown point, we can shrink the bracket on one side or another.
      # if f(x1) <= f(x2) then x0,x1,x2 form a new bracket. otherwise, f(x2) < f(x1) and x1,x2,x3 form a new bracket.
      # note that either x0 <= x1 <= x2 <= x3 or x0 >= x1 >= x2 >= x3.
      #
      # the only complexity is the selection of the new point to test. if the points are initially evenly spaced (|  |  |  |), then when the
      # bracket is shrunk by discarding one of the edges, one point will be in the center (|  |  |), and it's not possible to select a new
      # inner point that results in even spacing. the two inner points would end up on one side or another (| | |   |). the lopsided points
      # make the logic more complex and in the worst case, the bracket only shrinks by 25% each iteration. we can do better and simplify the
      # logic using the golden ratio (actually, its inverse). the inverse of the golden ratio is about 0.62, and its complement is about
      # 1 - 0.62 = 0.38. then, we choose new inner points such that x1 is 38% of the way between x0 and x3, and x2 is about 62% of the
      # way. (equivalently, x1 is 38% of the way between x0 and x3, and x2 is 38% of the way between x1 and x3, due to the special
      # properties of the golden ratio.) this results in a shape like (|  | |  |). when shrunk we get (|  | |), say, and the new point can
      # be chosen thus (| || |). this results in consistent performance, as the shrinkage is always the same 38%. any other arrangement
      # gives worse performance in the worst case. note that there's no guarantee that the initial bracket will conform to this shape, but
      # we can choose points so that it converges on the right shape

      x0 = bracket.high1
      x1 = x2 = nil
      x3 = bracket.high2

      # if the initial middle point is closer to the left side (e.g. |  |    |), choose the new point to closer to the right side
      if (x3 - bracket.low).abs > (bracket.low - x0).abs
        x1 = bracket.low                     # place x2 38% of the way from x3-x1 to put it in the right place. if x1 is not in the right
        x2 = x1 + (x3-x1)*INV_GR_COMPLEMENT  # place, the placement will tend to counteract x1's mispositioning
      else  # otherwise, the initial point is closer to the right side (or centered), so choose the new point closer to the right
        x2 = bracket.low;
        x1 = x2 - (x2-x0)*INV_GR_COMPLEMENT  # place x1 62% of the way from x0 to x2 (38% back from x2)
      end

      v1 = function.call(x1)
      v2 = function.call(x2);
      # in general, we can only expect to get the answer to within a fraction of the center value
      while (x3-x0).abs > (x1.abs+x2.abs)*tolerance  # while the bracket is still too large compared to the center values...
        if v2 < v1  # if f(x2) < f(x1) then we have f(x1) > f(x2) and f(x3) >= f(x2), so we can take x1,x2,x3 as the new bracket
          x = x2*INV_GOLDEN_RATIO + x3*INV_GR_COMPLEMENT
          x0 = x1
          x1 = x2
          v1 = v2
          x2 = x
          v2 = function.call(x)
        else  # otherwise, f(x1) <= f(x2), so we have f(x2) >= f(x1) and f(x0) >= f(x1), so we can take x0,x1,x2 as the new bracket
          x = x1*INV_GOLDEN_RATIO + x0*INV_GR_COMPLEMENT
          x3 = x2
          x2 = x1
          v2 = v1
          x1 = x
          v1 = function.call(x)
        end
      end

      # finally, when the bracket has shrunk to be very small, take the lower of v1 and v2 as the minimum
      if v1 < v2
        value = v1  # FIXME may need to output this somehow
        return x1
      else
        value = v2  # FIXME may need to output this somehow
        return x2
      end
    end

    INV_GOLDEN_RATIO_COMP = 0.38196601125010515  # one minus the inverse of the golden ratio, used by golden section search
    MAX_ITERATIONS = 100

    def self.brent(function, bracket, tolerance = SQRT_DOUBLE_PRECISION)
      raise "no function" unless function
      raise "tolerance must not be negative" if tolerance < 0

      # Brent's method combines the sureness of the golden section search with the parabolic interpolation described in BracketInside().
      # this allows it to converge quickly to the minimum if the local behavior of the function can be roughly approximated by a
      # parabola and to get there eventually if it can't. the difficulty is knowing when to switch between the two approaches. Brent's
      # method keeps track of six points: the two edges of the bracket, the points giving the least and second-least known values,
      # the previous least point from the last iteration (which was evaluated two iterations prior), and the most recently evaluated point.
      # in short, Brent's method uses parabolic interpolation when the interpolated point is in the bracket and the movement is less than
      # half the distance from the previous least point (evaluated two iterations prior). requiring it to be less ensures that the parabolic
      # interpolation is working (as the function should be getting smoother and the jumps smaller) and not cycling. using the point from
      # two iterations prior rather than one is a heuristic -- requiring two bad steps in a row before switching to golden section search

      left  = [bracket.high1, bracket.high2].min
      right = [bracket.high1, bracket.high2].max

      minPt = bracket.low
      secondMinPt = minPt
      prev2ndMinPt = minPt
      minVal = function.call(minPt)
      secondMinVal = minVal
      prev2ndMinVal = minVal
      step = 0
      prevStep = 0

      MAX_ITERATIONS.times do
        # we're done when the distance between the brackets is less than or equal to minPt*tolerance*2 and minPt is centered in the bracket
        mid = 0.5*(left+right)
        tol1 = tolerance * minPt.abs + (DOUBLE_PRECISION*0.001)  # prevent tol2 from being zero when minPt is zero
        tol2 = tol1 * 2
        if (minPt-mid).abs <= tol2 - 0.5*(right-left)
          value = minVal  # FIXME output?
          return minPt
        end

        if prevStep.abs <= tol1  # if the step we'd compare the parabolic interpolation against is too small (near the roundoff error)
          # we can't meaningfully compare the interpolation step against it, and the interpolation step is unlikely to be smaller than it,
          # so just do golden section search
          prevStep = (minPt >= mid ? left : right) - minPt
          step     = prevStep * INV_GOLDEN_RATIO_COMP
        else # otherwise, the previous step was substantial, so attempt parabolic interpolation
          # see BracketInward() for a general description of how the parabolic interpolation works. one difference is that BracketInward()
          # computes the position of the vertex, but actually the step size to get from the old minimum point to the vertex
          g = secondMinPt*(prev2ndMinVal-minVal)
          h = minPt*(secondMinVal-prev2ndMinVal)
          j = prev2ndMinPt*(minVal-secondMinVal)
          d = g + h + j; # calculate the denominator
          # if the denominator is zero, use a point that will force a subdivision step
          x = d == 0 ? Float::INFINITY : (secondMinPt*g + minPt*h + prev2ndMinPt*j)/(2*d)
          newStep = x - minPt # subtract minPt from the vertex to get the step size

          # if the step size isn't less than than half the previous step size, or would take us out of bounds...
          if newStep.abs >= (0.5*prevStep).abs || x <= left || x >= right
            prevStep = (minPt >= mid ? left : right) - minPt # then use golden section search
            step     = prevStep * INV_GOLDEN_RATIO_COMP
          else # otherwise, the interpolation is valid
            prevStep = step
            step     = newStep
            if x-left < tol2 || right-x < tol2
              step = with_sign(tol1, mid-minPt)
            end
          end
        end

        # if the step size is greater than the roundoff error, use it. otherwise, use a minimum step size to ensure we're actually getting
        # somewhere
        x = minPt + (step.abs >= tol1 ? step : with_sign(tol1, step))
        v = function.call(x)

        if v <= minVal # if the new value is less than or equal to the smallest known value...
          # update the bracket, making the old best point an edge. we have f(left) >= f(minPt) and f(right) >= f(minPt) and f(minPt) >= f(x)
          if x >= minPt
            left = minPt  # if the new point is to the right of the old minimum, a new bracket is minPt, x, right
          else
            right = minPt  # otherwise, it's to the left, and a new bracket is left, x, minPt
          end

          # make the minimum point the previous minimum point, the new point the minimum point, etc.
          prev2ndMinPt  = secondMinPt
          prev2ndMinVal = secondMinVal
          secondMinPt   = minPt
          secondMinVal  = minVal
          minPt  = x
          minVal = v
        else # the new value is greater than the smallest known value...
          # update the bracket, making the new point an edge. we have f(left) >= f(minPt) and f(right) >= f(minPt) and f(x) >= f(minPt)
          if x < minPt
            left = x  # if the new point is to the left of the old minimum, a new bracket is x, minPt, right
          else
            right = x  # otherwise, it's to the right, and a new bracket is left, minPt, x
          end

          if v <= secondMinVal || secondMinPt == minPt  # if the new value is between the minimum value and the second minimum value...
            prev2ndMinPt  = secondMinPt
            prev2ndMinVal = secondMinVal  # then make the new point the second minimum value
            secondMinPt   = x
            secondMinVal  = v
          # otherwise, if it's between the second minimum value and the previous second minimum value...
          elsif v <= prev2ndMinVal || prev2ndMinPt == minPt || prev2ndMinPt == secondMinPt
            prev2ndMinPt  = x  # make it the previous second minimum value
            prev2ndMinVal = v
          end
        end
      end

      raise "minimum not found"
    end

    def self.with_sign(value, sign)
      (sign < 0) ^ (value < 0) ? -value : value
    end

    GOLDEN_RATIO = 1.61803398874989485
    MAX_STEP = 100

    def self.bracket_outward(function, x1, x2)
      raise "no function" unless function
      x1 = x1.to_f
      x2 = x2.to_f

      # we'll use the golden ratio for the expansion factor. this is related to the fact that the optimal shape of a bracket for
      # minimization via subdivision shrinks it by a factor of the golden ratio on each iteration (see GoldenSection). so we'll strive to
      # output a bracket of this optimal shape to increase the efficiency of routines that make use of subdivision

      # to bracket outward, we'll maintain three points x1, xm, and x2 where f(x1) >= f(xm), and we'll attempt to find a point x2 where
      # f(x2) >= f(xm). (the x1 and x2 parameters become the initial values of x1 and xm, in whichever order is needed to maintain the
      # invariant.) if haven't found a bracket yet, then we have f(x1) >= f(xm) > f(x2), so the three points x1, xm, x2 are heading
      # downhill. we can then take xm = x2 and expand x2 by some amount. if f(x2) has not decreased after doing that, then f(x2) >= f(xm)
      # and we're done. rather than increasing x2 blindly in many steps, we can attempt to fit a parabola to the three points and find its
      # vertex. that should take us close to the turning point if the function can be locally well-approximated by an upward-opening
      # parabola. if the quadratic fit doesn't help (because the function value increased at the vertex point), then we'll expand by a
      # constant factor -- the golden ratio
      v1 = function.call(x1)
      vm = function.call(x2)
      if vm > v1
        x1, x2 = x2, x1
        v1, vm = vm, v1
      end

      # get the initial guess for x2 by merely expanding the bracket by a constant factor
      xm = x2
      x2 = xm + (xm-x1)*GOLDEN_RATIO
      v2 = function.call(x2)

      while vm > v2  # while we haven't found a suitable value for x2...
        # see BracketInward for a description of how the parabolic fit works
        g = x1*(v2-vm)
        h = xm*(v1-v2)
        j = x2*(vm-v1)
        d = g + h + j
        xLimit = xm + (x2-xm)*MAX_STEP
        expand = true

        if d != 0  # if we can fit a proper parabola to it...
          x = (x1*g + xm*h + x2*j) / (2*d)  # find the vertex of the parabola
          if (xm-x)*(x-x2) > 0  # if the vertex is between xm and x2...
            v = function.call(x)
            if v < v2
              # if f(x) < f(x2), then we have a minimum with the points xm,x,x2. we need f(x) <= f(xm) and f(x) <= f(x2). the first
              # is guaranteed by the shape of the parabola. since the vertex is between xm and x2, which the parabola passes
              # through, it must either be above or below both. so since f(x) < f(x2) it must also be the case that f(x) < f(xm)
              x1 = xm
              v1 = vm
              xm = x
              vm = v
              break
            elsif v > vm
              # if f(x) > f(xm), then we have a minimum with the points x1,xm,x. we need f(xm) <= f(x1) and f(xm) <= f(x). the
              # first condition is guaranteed by the invariant f(x1) >= f(xm)
              x2 = x
              v2 = v
              break
            end
            # otherwise, the function value was between f(xm) and f(x2). this doesn't give us a minimum, and with the vertex inside the
            # interval, it doesn't expand the interval either. so we'll expand the interval by a fixed factor
            expand = true
          end
        else # otherwise, the parabola was degenerate because the points are colinear
          x = xLimit; # move x as far along the line as we'll allow
        end

        if (x2-x)*(x-xLimit) > 0  # if x is between x2 and xLimit...
          v = function.call(x)
          if v < v2
            # if f(x) < f(x2) then we have f(x1) >= f(xm) > f(x2) > f(x), so we can discard xm to get x1,x2,x. this allows the
            # interval to keep expanding by a fixed factor (since the expansion is based on xm and x2). then we expand the result
            xm = x2
            vm = v2
            x2 = x
            v2 = v
            expand = true
          else
            # otherwise, we have f(x1) >= f(xm) > f(x2) <= f(x). this is a minimum with xm,x2,x if f(xm) <= f(x). we'll do the shift below
            # and the check at the start of the next iteration. in any case we want to shift x -> x2 -> xm to keep the expansion geometric
            expand = false
          end
        elsif (x-xLimit)*(xLimit-x2) >= 0  # if x is beyond than the limit...
          x = xLimit  # clip it to the limit and then shift it into place
          v = function.call(x)
          expand = false
        end

        if expand
          x = x2 + (x2-xm)*GOLDEN_RATIO
          v = function.call(x)
        end

        x1 = xm
        v1 = vm
        xm = x2
        vm = v2
        x2 = x
        v2 = v
      end

      # if the size of the interval is too large to be represented (e.g. we didn't find a minimum), then we failed
      raise "infinite" if (x2-x1).infinite?
      return MinimumBracket.new(x1, xm, x2)
    end

    BFGS_TOLERANCE = 1e-8
    SCALED_MAX_STEP = 100
    BFGS_PARAM_TOLERANCE = DOUBLE_PRECISION * 4

    # Finds a local minimum of multi-dimensional function near the given initial point.
    def self.bfgs(function, x, tolerance = BFGS_TOLERANCE)
      arity = x.count
      raise "function arity is #{function.arity} but #{arity} values supplied" unless arity == function.arity
      raise "tolerance must not be negative" if tolerance < 0

      step     = [0.0] * arity
      tmp      = [0.0] * arity
      gradDiff = [0.0] * arity
      # occasionally, it stalls. if that happens, we'll try restarting. (we do two 100 iteration tries rather than one 200 iteration try.)
      2.times do
        invHessian = Matrix.identity(arity)
        value = function.call(*x)
        maxStep = [MathHelpers.get_magnitude(x), arity].max * SCALED_MAX_STEP
        gradient = function.gradient(*x)
        step = MathHelpers.negate_vector(gradient)  # the initial step is the opposite of the gradient (i.e. directly downhill)

        MAX_ITERATIONS.times do
          # move in the step direction as far as we can go. the new point is output in 'tmp'
          value = FindRoot.line_search(function, x, value, gradient, step, tmp, maxStep)
          step = MathHelpers.subtract_vectors(tmp, x)  # store the actual distance moved into 'step'
          x = tmp.dup

          # if the parameters are barely changing, then we've converged
          return value if get_parameter_convergence(x, step) <= BFGS_PARAM_TOLERANCE

          # evaluate the gradient at the new point. if the gradient is about zero, we're done
          gradDiff = gradient.dup  # copy the old gradient
          gradient = function.gradient(*x)  # get the new gradient
          return value if get_gradient_convergence(x, gradient, value) <= tolerance  # check the new gradient for convergence to zero

          # compute the difference between the new and old gradients, and multiply the difference by the inverse hessian
          MathHelpers.SubtractVectors(gradient, gradDiff, gradDiff)
          MathHelpers.Multiply(invHessian, gradDiff, tmp)

          double fac = MathHelpers.DotProduct(gradDiff, step);
          double gdSqr = MathHelpers.SumSquaredVector(tmp), stepSqr = MathHelpers.SumSquaredVector(step);
          if(fac > Math.Sqrt(gdSqr*stepSqr*IEEE754.DoublePrecision)) # skip the hessian update if the vectors are nearly orthogonal
            fac = 1 / fac;
            double fae = MathHelpers.DotProduct(gradDiff, tmp), fad = 1 / fae;

            gradDiff.each_index do |i|
              gradDiff[i] = fac*step[i] - fad*tmp[i]
            end

            step.each_index do |i|
              step.each_index do |j|
                double element = invHessian[i, j] + fac*step[i]*step[j] - fad*tmp[i]*tmp[j] + fae*gradDiff[i]*gradDiff[j];
                invHessian[i, j] = element;
                invHessian[j, i] = element;
              end
            end
          end

          step.each_index do |i|
            step[i] = -MathHelpers.SumRowTimesVector(invHessian, i, gradient);
          end
        end
      end

      raise "minimum not found"
    end

    def self.get_parameter_convergence(x, step)
      maxValue = 0
      x.each_index do |i|
        value = step[i].abs / [x[i].abs, 1].max
        maxValue = value if value > maxValue
      end
      return maxValue
    end

    def self.get_gradient_convergence(x, gradient, value)
      maxValue = 0
      divisor = [value.abs, 1].max
      x.each_index do |i|
        component = gradient[i].abs * [x[i].abs, 1].max / divisor
        maxValue = component if component > maxValue
      end
      return maxValue
    end
  end

  module MathHelpers
    def self.get_magnitude(vector)
      return Math.sqrt(sum_squared_vector(vector))
    end

    def self.sum_squared_vector(vector)
      return vector.inject(0) do |sum, value|
        sum += value*value
      end
    end

    def self.negate_vector(vector)
      return vector.map { |v| -v }
    end

    def self.scale_vector(vector, scale)
      return vector.map { |v| v * scale }
    end

    def self.dot_product(a, b)
      return a.each_index.inject(0) do |sum, i|
        sum += a[i]*b[i]
      end
    end

    def self.subtract_vectors(lhs, rhs)
      return lhs.each_index.map do |i|
        lhs[i] - rhs[i]
      end
    end
  end

  class FindRoot
    ALPHA = 0.0001

    def self.line_search(function, x, value, gradient, step, newX, maxStep = Float::INFINITY)
      # when performing Newton's method against a function, taking the full Newton step may not decrease the function's value. the
      # step points in the direction of decrease, but since it's based on the derivative at a single point, it's only guaranteed to
      # initially decrease. as we go farther away from the point, the function can do who knows what. so if the Newton step would do
      # newX = x + step, a line search will find a factor F such newX = x + F*step represents is sure to represent a decrease in the
      # function's value, where 0 < F <= 1. in general, we want to set F = 1, representing the full Newton step, but if this doesn't
      # decrease the function value sufficiently, then we try lower values of F. the function value is guaranteed to decrease if F is small
      # enough, although there's no guarantee that it will decrease sufficiently.
      #
      # we will consider a decrease in value to be sufficient if it is a certain fraction of the ideal decrease implied by the full Newton
      # step, that is, if f(newX) <= f(x) + c*gradient*step, where c is the fraction that we want and gradient is the function's gradient
      # at x. we can get away with a small value for c. Numerical Recipes suggests 0.0001. this prevents f() from decreasing too slowly
      # relative to the step length. the routine also needs to avoid taking steps that are too small.
      #
      # the way new step values are chosen (if the full Newton step is not good enough) is as follows:
      # if we take the function g(F) = f(x + F*step), then g'(F) = gradient*step. we can then attempt to minimize g(F), which will have the
      # effect of choosing a value for F that makes the new f() value as small as possible. to minimize g(F) we model it using the available
      # information and then minimize the model. at the start, we have g(0) and g'(0) available as the old f() value and gradient*step,
      # respectively. after trying the Newton step, we also have g(1). using this information, we can model g(F) as a quadratic that
      # passes through the two known points:
      #     g(F) ~= (g(1) - g(0) - g'(0))*F^2 + g'(0)*F + g(0)
      # if F is 0, then clearly the quadratic equals the constant term, so the constant term must be g(0). given that, if F is 1, then the
      # non-constant terms must equal g(1) - g(0), so that when the constant term is added, the result is g(1). i'm not exactly sure why
      # g'(0) is used the way it is. there's probably an important reason for choosing it as the linear term. anyway, this is the
      # quadratic model used in NR.
      #
      # the quadratic is a parabola that has its minimum when its derivative is zero. so we take the derivative (treating the coefficients
      # as constants) and set it equal to zero. if g(F) ~= a*F^2 + b*F + d, then the derivative is 2a*F + b, and solving for F at 0 we get
      # F = -b/2a, or:
      #     F = -g'(0) / 2(g(1) - g(0) - g'(0))
      # according to Numerical Recipes, it can be shown that usually F must be less than or equal to 1/2 when a (the constant we chose
      # earlier) is small. so we enforce that F is <= 1/2. we also want to prevent the step from being too small, so we enforce that
      # F >= 0.1.
      #
      # if the new step is not good enough, then we have more information. on future attempts, we can model g(F) as a cubic, using the
      # previous two values of F (which we'll call F' and F''). then we have:
      #     g(F) ~= a*F^3 + b*F^2 + g'(0)*F + g(0)
      # to find the values of the coefficients a and b, we have to constrain the equation so it passes through the known values g(F') and
      # g(F''). substituting those in, we get two equations that we can solve for the two unknowns:
      #     a*F'^3  + b*F'^2  + g'(0)*F'  + g(0) = g(F')
      #     a*F''^3 + b*F''^2 + g'(0)*F'' + g(0) = g(F'')
      # once we have the coefficients a and b, we can find the minimum of the cubic. if we make certain assumptions like F > 0, and others
      # that i don't quite understand (e.g. assumptions about the values of a and b?), we can use the tactic of solving for where the
      # derivative is 0. since the derivative is quadratic, there would normally be two solutions, but based on the assumptions, we can
      # discard one of them, and we end up with F = (-b + sqrt(b^2 - 3a*g'(0))) / 3a. we then enforce that the new F is between 0.1 and 0.5
      # times the previous F and try again.

      # first limit the step length to maxStep
      if maxStep.finite?
        length = MathHelpers.get_magnitude(step)
        step = MathHelpers.scale_vector(step, maxStep/length) if length > maxStep
      end

      # then calculate the slope as the dot product between the step and the gradient -- this is g'(0) in the description above
      slope = MathHelpers.dot_product(gradient, step)
      raise "invalid step vector, or too much roundoff error occurred" if slope >= 0

      # find the minimum allowable factor. if the factor drops below this value, then we give up
      minFactor = 0
      x.each_index do |i|
        tempFactor = step[i].abs / [1, x[i].abs].max
        minFactor = tempFactor if tempFactor > minFactor
      end
      minFactor = DOUBLE_PRECISION / minFactor

      # start with a factor of 1, representing the full Newton step
      factor = 1
      prevFactor = 0
      prevValue = 0
      while true  # while we're looking for a suitable step size...
        # try the current step size
        newX.each_index do |i|
          newX[i] = x[i] + step[i]*factor
        end
        newValue = function.call(*newX)

        if factor < minFactor  # if it's too small, then give up and return true, indicating that it has converged on a minimum
          newX = x.dup  # put the original parameter and value back
          return value
        elsif newValue <= value + ALPHA*factor*slope
          raise [newValue, value, ALPHA, factor, slope].inspect
          # otherwise, if the function value has decreased significantly (see above)...
          # this is basically checking if f(newX) <= f(x) + c*F*(gradient*step)
          return nil  # return nil, indicating that it decreased and hasn't, so far as we know, hit a minimum
        else
          # otherwise, the decrease wasn't sufficient and we have to find a smaller factor
          nextFactor = nil
          if factor == 1  # if this is the first time we've had to decrease F, use the quadratic model (F = -g'(0) / 2(g(1) - g(0) - g'(0)))
            nextFactor = -slope / (2*(newValue-value-slope))
          else  # otherwise, it's the second or later time, so use the cubic model
            # compute the coefficients of the cubic, a and b (discussed above)
            rhs1 = newValue - value - factor*slope
            rhs2 = prevValue - value - prevValue*slope
            a = (rhs1/(factor*factor) - rhs2/(prevFactor*prevFactor)) / (factor - prevFactor)
            b = (-prevFactor*rhs1/(factor*factor) + factor*rhs2/(prevFactor*prevFactor)) / (factor - prevFactor)

            # the new F is found by solving for a point where the derivative is zero: F = (-b + sqrt(b^2 - 3a*g'(0))) / 3a
            if a == 0
              # if that formula would cause division by zero, we can simplify the cubic by removing the cubic term (since a is 0),
              # getting b*F^2 + g'(0)*F + g(0), and solve for a point where its derivative is zero: F = -g'(0) / 2b
              nextFactor = -slope / (2*b)
            else # otherwise, there wouldn't be a division by zero, so solve for F
              discriminant = b*b - 3*a*slope
              if discriminant < 0
                nextFactor = 0.5 * factor  # if there's no real solution, just set F to be as big as possible
              elsif b <= 0
                nextFactor = (-b+Math.sqrt(discriminant)) / (3*a)  # if the solution would come out normally, use it
              else
                nextFactor = -slope / (b + Math.Sqrt(discriminant))  # otherwise... (i don't understand this bit)
              end
            end

            if nextFactor > 0.5*factor
              nextFactor = 0.5*factor  # clip the new factor to be no larger than half the old factor
            end
          end

          # if the function went out of bounds or whatever, reduce the step size. this prevents the function from going into an infinite
          # loop and helps solve problems based on barrier methods
          nextFactor = 0 if nextFactor.nan?

          prevFactor = factor    # keep track of the previous factor (F'')
          prevValue  = newValue  # and the previous value g(F'')
          factor     = [nextFactor, 0.1*factor].max  # clip the new factor to be no smaller than one tenth the old factor
        end
      end
    end
  end
end
