require 'adam_math/ieee754'

module AdamMath
  module FindRoot
    ALPHA = 0.0001
    MAX_ITERATIONS = 100

    BRACKET_EXPANSION = 1.6
    BRACKET_MAX_TRIES = 50

    class RootNotFoundError < StandardError; end
    class RootNotBracketedError < StandardError; end

    def self.bracket_outward(function, initialGuess)
      raise "null function" unless function
      initialGuess.validate
      initialGuess = initialGuess.mutable

      vMin = function.call(initialGuess.min)
      vMax = function.call(initialGuess.max)
      BRACKET_MAX_TRIES.times do
        return true if vMin*vMax < 0  # if the two values have opposite signs, assume there's a zero crossing
        if vMin.abs < vMax.abs  # otherwise, if the minimum side of the interval is closer to zero, expand in that direction
          initialGuess.min += (initialGuess.min - initialGuess.max) * BRACKET_EXPANSION
          vMin = function.call(initialGuess.min)
        else # otherwise, the maximum side is closer (or they're the same distance), so expand in that direction
          initialGuess.max += (initialGuess.max - initialGuess.min) * BRACKET_EXPANSION
          vMax = function.call(initialGuess.max)
        end
      end

      # if one of the values was zero on the last iteration, then we would have expanded the iteration to contain a zero crossing or
      # zero touching, but would have fallen out of the loop before we could detect that and return true. so give it one last chance
      return vMin * vMin <= 0
    end

    def self.bracket_inward(function, interval, segments)
      raise "null function" unless function
      raise "segments must be positive" if segments <= 0
      interval.validate
      interval = interval.mutable

      intervals = []
      segmentSize = (interval.max - interval.min) / segments
      max  = interval.min
      vMin = function.call(interval.min)

      brackets = []
      (0...segments).each do |i|
        max = i == segments-1 ? interval.max : max + segmentSize  # make sure the end of the last segment exactly matches the the interval
        vMax = function.call(max)
        if vMin*vMax <= 0
          brackets << RootBracket.new(interval.min, max)  # if a zero crossing (or zero touching) was found, return it
        end
        vMin = vMax
        interval.min = max
      end

      return brackets
    end


    def self.get_default_tolerance(interval)
      return (interval.min.abs + interval.max.abs) * (0.5 * IEEE754::DOUBLE_PRECISION)
    end

    # Returns a root of the function, to within the specified tolerance. See the remarks for more details.
    def self.unbounded_newton_raphson(function, interval, tolerance=get_default_tolerance(interval))
      raise "null function" unless function
      raise "negative tolerance" if tolerance < 0
      interval.validate

      # Newton's method (also called Newton-Raphson after Joseph Raphson who independently invented the method some time after Newton, but
      # who published it before Newton) uses a function's derivative to estimate the location of the root. it works by repeatedly taking a
      # point and effectively intersecting the tangent line with the x axis and using that as the location for the next point to try. among
      # other shortcomings, this can cause it to go to infinity if the tangent line is horizontal (or nearly horizontal), and in some rare
      # cases it can enter a loop where the tangent from point A goes to point B, and the tangent from point B goes to point A. but in
      # general, it is an effective method.
      #
      # given a guess for the root location x, Newton's method takes x - f(x)/f'(x) as the next guess. this is based on the Taylor series
      # expansion of a function around a point: f(x+d) ~= f(x) + f'(x)*d + f''(x)*d^2/2 + f'''(x)*d^3/6 + ... for a small value of d. it is
      # assumed that the function is smooth and the higher order terms don't contribute much and can be safely ignored. (this is often, but
      # not always, true.) if we take d to be quite small and assume the function is well-behaved, then it simplifies into
      # f(x+d) ~= f(x) + f'(x)*d. if the function is approximately linear around that point, then f(x+d) = 0 would imply that
      # d = -f(x) / f'(x). (this is the step where the tangent line is intersected with the x axis by solving the linear equation.) thus,
      # the update step is x+d, or x - f(x)/f'(x).

      step = nil
      guess = (interval.max + interval.min) * 0.5
      MAX_ITERATIONS.times do
        step = function.call(guess) / function.call_derivative(guess, 1)
        guess -= step
        break if (interval.min-guess) * (guess-interval.max) < 0  # if it went outside the interval, abort
        return guess if step.abs <= tolerance  # if we're within the desired tolerance, then we're done
      end

      raise RootNotFoundError
    end

    # Returns a root of the function, to within the specified tolerance. See the remarks for more details.
    def self.bounded_newton_raphson(function, interval, tolerance=get_default_tolerance(interval))
      raise "null function" unless function
      raise "negative tolerance" if tolerance < 0
      interval.validate
      interval = interval.mutable

      vMin = function.call(interval.min)
      vMax = function.call(interval.max)
      return interval.min if vMin == 0
      return interval.max if vMax == 0
      raise RootNotBracketedError if vMin*vMax > 0

      interval = interval.swap if vMin > 0  # make the search go from low (negative) to high (positive)

      # see UnboundedNewtonRaphson() for an implementation of the basic Newton's method. in addition to the basic Newton's method, this
      # implementation adds bounds checking to prevent Newton's method from diverging wildly if it encounters a near-zero derivative, and
      # adds a convergence check to ensure that it isn't getting stuck in rare cases or slowing down too much near a root with a derivative
      # of zero. when that happens, it switches to the subdivision method

      guess = (interval.max + interval.min) * 0.5
      step  = (interval.max - interval.min).abs
      prevStep = step
      value = function.call(guess)
      deriv = function.call_derivative(guess, 1)
      MAX_ITERATIONS.times do
        # in order to see decide whether to do Newton's method or simple subdivision in this iteration, we'll see whether the Newton step
        # 1) would keep the estimate in bounds, and 2) would probably decrease the magnitude of the function's value more than subdivision
        #
        # in order for the Newton step to keep the estimate within bounds (after doing x = x - f(x)/f'(x)), we would need to have:
        # min <= x - f(x)/f'(x) <= max
        # min-x <= -f(x)/f'(x) <= max-x
        # x-min >= f(x)/f'(x) >= x-max
        # (x-min)*f'(x) >= f(x) >= (x-max)*f'(x)
        # (x-min)*f'(x) - f(x) >= 0 >= (x-max)*f'(x) - f(x)
        # which is to say that (x-min)*f'(x) - f(x) and (x-max)*f'(x) - f(x) must not have the same sign. we can check that by multiplying
        # them together and seeing if the result is positive.
        giveUp = false
        if ((((guess-interval.max)*deriv - value) * ((guess-interval.min)*deriv - value)) > 0 || # if the Newton step would go out of bounds
            (2*value).abs > (prevStep*deriv).abs) # or the function value isn't decreasing fast enough (not sure why this works)...
          prevStep = step  # then use bisection
          step     = 0.5 * (interval.max - interval.min)  # just step to the middle of the current interval
          guess    = interval.min + step
          giveUp = guess == interval.min  # if the step was so small as to make no difference in value, then we're as close as we can get
        else # otherwise, the newton step would likely help, so use it instead
          prevStep = step
          step     = value / deriv  # compute the update amount f(x) / f'(x)
          temp = guess
          guess -= step
          giveUp = guess == temp  # if the step was so small as to make no difference in the value, then we're as close as we can get
        end

        return guess if step.abs <= tolerance  # if we're within the desired tolerance, then we're done
        break if giveUp  # otherwise, if we can't go any further, give up

        value = function.call(guess)
        deriv = function.call_derivative(guess, 1)

        # shrink the interval around the current best guess
        if (value < 0)
          interval.min = guess
        else
          interval.max = guess
        end
      end

      raise RootNotFoundError
    end

    def self.brent(function, interval, tolerance=get_default_tolerance(interval))
      raise "null function" unless function
      raise "negative tolerance" if tolerance < 0
      interval.validate

      a = interval.min
      b = interval.max
      va = function.call(a)
      vb = function.call(b)

      return interval.min if va == 0
      return interval.max if vb == 0
      raise RootNotBracketedError if va*vb > 0

      # the secant method for root finding takes two points (initially the edges of the interval) and uses a linear interpolation between
      # them (intersecting it with the x axis) to get the next estimate of where the root is. it converges quite quickly, but it is possible
      # that the secant method will diverge from the solution given a point where the secant line takes it way off course. the false
      # position method is similar except that it updates the points defining the line in such a way that they always remain bracketed (by
      # keeping track of an older point to allow sometimes updating only one of the endpoints). this is slower, but surer. ridder's method
      # evaluates the point in the midpoint of the line as well, and uses some magic to factor out an exponential factor to turn the three
      # points into a straight line, and applies the false position method to the modified points, producing a method that converges
      # quadratically while remaining bracketed. ridder's method generally works very well.
      #
      # however, all of those methods assume approximately linear behavior between the root estimates, and can get bogged down with
      # pathological functions, taking take many iterations to converge -- many more than the simple subdivision method, which is at least
      # guaranteed linear convergence. the van Wijngaarden-Dekker-Brent method (or Brent's method for short) works by using inverse
      # quadratic interpolation to fit an inverse quadratic function to the points, but if the result would take the next step out of
      # bounds, or if it wouldn't shrink the bounds quickly enough, then uses subdivision instead. in this way, it achieves generally
      # quadratic convergence while guaranteeing at least linear convergence. unlike the simpler methods, i can't claim to actually
      # understand all the math behind it, but here's the implementation

      tolerance *= 0.5  # we actually use half the tolerance in the math below, so do the division only once

      # a, b, and c are the three points defining the current estimate of the root's position. va, vb, and vc are the values of the function
      # corresponding those points. b corresponds to the current best estimate
      c = b
      vc = vb
      range = 0
      e = 0
      MAX_ITERATIONS.times do
        if vb*vc > 0  # if f(b) and f(c) have the same sign (which won't be zero because we've already handled that case)...
          # then we have vb and vc on one side of zero and va on the other side. discard c and replace it with a copy of a. this gives
          # a and c on one side of the root, and b on the other
          c  = a
          vc = va
          e  = range = b-a
        end

        if (vc.abs < vb.abs) # if f(c) is closer to zero than f(b)...
          # make the one closer to zero b, which is supposed to be our best estimate so far, and discard a
          a=b
          b=c
          c=a
          va=vb
          vb=vc
          vc=va
        end

        # check to see how well we're converging on the root
        tol = 2*IEEE754::DOUBLE_PRECISION * b.abs + tolerance
        xm = 0.5 * (c-b)

        return b if xm.abs <= tol || vb == 0  # if the current best estimate is close enough, return it

        if e.abs >= tol && va.abs > vb.abs  # if the bounds are increasing quickly enough...
          # attempt inverse quadratic interpolation. the next root estimate basically equals b + P/Q where:
          # P = S * (T*(R-T)*(c-b) - (1-R)*(b-a)) and
          # Q = (T-1)*(R-1)*(S-1) given
          # R = f(b) / f(c)
          # S = f(b) / f(a)
          # T = f(a) / f(c)
          s = vb / va
          if a == c  # if a = c (a common case), then T = 1 and (a-b) = (c-b) = 2*xm, and the expression simplifies...
            # P = S * ((R-1)*2xm + (1-R)*2xm) = S * 2xm * ((R-1) + (1-R)) = S * 2xm = S * 2 * 0.5 * (c-b) = S * (c-b)
            p = s * (c-b)
            # this seems like it should simplify Q = (T-1)*(R-1)*(S-1) = (1-1)*(R-1)*(S-1) = 0. but that would lead to division by zero
            # later when we divide P by Q, so Brent's method uses this instead. i'm not sure why.
            q = 1 - s
          else  # otherwise, we use the equations above (with some changes that i don't exactly understand)
            r = vb / vc
            q = va / vc  # use q to hold T
            p = s * (q*(q-r)*(c-b) - (r-1)*(b-a))  # this seems to be negated from the expected formula. i'm not sure why.
            q = (q-1) * (r-1) * (s-1)
          end

          if p > 0
            q = -q
          else
            p = -p
          end

          if 2*p < [3*xm*q - (tol*q).abs, (e*q).abs].min  # if the interpolation puts us within bounds, then use it
            e = range
            range = p / q;
          else  # otherwise, use bisection
            range = xm
            e = range
          end
        else
          range = xm
          e = range
        end

        a  = b
        va = vb
        b += range.abs > tol ? range : MathHelpers.with_sign(tol, xm)
        vb = function.call(b)
      end

      raise RootNotFoundError
    end

    # Returns a root of the function, to within the specified tolerance. See the remarks for more details.
    def self.subdivide(function, interval, tolerance=get_default_tolerance(interval))
      raise "null function" unless function
      raise "negative tolerance" if tolerance < 0
      interval.validate

      vMin = function.call(interval.min)
      vMax = function.call(interval.max)
      return interval.min if vMin == 0
      return interval.max if vMax == 0
      raise RootNotBracketedError if vMin*vMax > 0

      # do a simple binary search of the interval
      difference = start = nil
      if vMin < 0
        difference = interval.max - interval.min
        start      = interval.min
      else
        difference = interval.min - interval.max;
        start      = interval.max
      end

      MAX_ITERATIONS.times do
        difference *= 0.5
        mid = start + difference
        value = function.call(mid)
        start = mid if value <= 0
        return mid if difference.abs <= tolerance || value == 0
      end

      raise RootNotFoundError
    end

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
      minFactor = IEEE754::DOUBLE_PRECISION / minFactor

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
