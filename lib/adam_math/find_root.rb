require 'adam_math/ieee754'

module AdamMath
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
