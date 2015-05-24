require 'matrix'
require 'gsl'
require 'adam_math/ieee754'
require 'adam_math/math_helpers'
require 'adam_math/find_root'

module AdamMath
  module Minimize
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

    FMinimizer = GSL::Min::FMinimizer
    MAX_ITERATIONS = 100
    TOLERANCE = 1.5e-7

    def self.golden_section(function, bracket, tolerance = TOLERANCE)
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

      return minimize(FMinimizer::GOLDENSECTION, function, bracket, tolerance)
    end

    def self.brent(function, bracket, tolerance = TOLERANCE)
      # Brent's method combines the sureness of the golden section search with the parabolic interpolation described in BracketInside().
      # this allows it to converge quickly to the minimum if the local behavior of the function can be roughly approximated by a
      # parabola and to get there eventually if it can't. the difficulty is knowing when to switch between the two approaches. Brent's
      # method keeps track of six points: the two edges of the bracket, the points giving the least and second-least known values,
      # the previous least point from the last iteration (which was evaluated two iterations prior), and the most recently evaluated point.
      # in short, Brent's method uses parabolic interpolation when the interpolated point is in the bracket and the movement is less than
      # half the distance from the previous least point (evaluated two iterations prior). requiring it to be less ensures that the parabolic
      # interpolation is working (as the function should be getting smoother and the jumps smaller) and not cycling. using the point from
      # two iterations prior rather than one is a heuristic -- requiring two bad steps in a row before switching to golden section search

      return minimize(FMinimizer::BRENT, function, bracket, tolerance)
    end

    def self.minimize(minimizer, function, bracket, tolerance)
      raise "no function" unless function
      raise "tolerance must not be negative" if tolerance < 0

      xmin = bracket.low
      xlow = [bracket.high1, bracket.high2].min
      xup  = [bracket.high1, bracket.high2].max

      gsl_function = GSL::Function.alloc do |x|
        v = function.call(x)
        v = Float::MAX if v.infinite? # no way to catch infinite errors
        v
      end
      solver = FMinimizer.alloc(minimizer)
      solver.set(gsl_function, xmin, xlow, xup)

      MAX_ITERATIONS.times do
        solver.iterate
        status = solver.test_interval(tolerance, tolerance)
        return solver.x_minimum if status == GSL::SUCCESS
        break unless status == GSL::CONTINUE
      end

      raise "minimum not found"
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
    BFGS_PARAM_TOLERANCE = IEEE754::DOUBLE_PRECISION * 4

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
end
