require 'gsl'
require 'autocrew/solver/constraint_enforcement'
require 'autocrew/solver/penalty_function'

module Autocrew::Solver
  # Solves a general constrained optimization problem by solving a series of related unconstrained optimization problems.
  #
  # This class works based on the fact that a constrained optimization problem can be represented as functions f(x), representing the
  # objective without constraints, and c(x), representing how near the parameters are to violating the constraints, and that minimizing the
  # new function h(x) = f(x) + r*p(c(x)) is equivalent to solving the original constrained problem in the limit as r goes to either
  # infinity or zero (depending on the "ConstraintEnforcement" method), and where p(e) is a function that converts the measure
  # of how near the parameters are to violating the constraints into a penalty value.
  class ConstrainedMinimizer
    attr_reader :function, :bounds, :constraints, :constraint_enforcement

    class NoMinimumFoundError < StandardError
      attr_reader :last_result

      def initialize(last_result)
        @last_result = last_result
      end
    end

    class Stats
      attr_reader :iterations, :last_value

      def initialize
        @iterations = 0
        @last_value = nil
      end

      def after_iterate(minimizer)
        @iterations += 1
        @last_value = minimizer.f
      end
    end

    # Initializes the "ConstrainedMinimizer" with the objective function to minimize.
    def initialize(function)
      raise "not a function: #{function.inspect}" unless function.respond_to?(:arity)
      @function = function

      # The multiplier applied to be penalty on the first iteration. On each later
      # iteration, the penalty multiplier will be multiplied by a factor of "penaltychangefactor".
      @base_penalty_multiplier = 1.0

      # The factor by which the penalty changes on each iteration after the first. The default is 100, indicating
      # that the penalty multiplier changes by a factor of 100 on each iteration. (For penalty methods (the default), the penalty
      # multiplier increases by this factor each iteration, but for barrier methods, it decreases.) Increasing the value generally decreases
      # the number of iterations required to solve the problem, but increases the chance of missing the answer entirely.
      @penalty_change_factor = 100.0

      # The method by which the constraints and bounds will be enforced.
      @constraint_enforcement = ConstraintEnforcement::QuadraticPenalty.new

      # The constraint tolerance. The minimization process will be terminated if the fractional contribution of the
      # penalty to the function value is no greater than the constraint tolerance. Larger values will allow the process to terminate with a
      # greater degree of constraint violation.
      @constraint_tolerance = 1e-9

      # The gradient tolerance. Each iteration of the minimization process will attempt to reduce the gradient to
      # zero, but since it is unlikely to ever reach zero exactly, it will terminate when the gradient is fractionally less than the
      # gradient tolerance. Larger values allow the process to terminate slightly further from the minimum.
      # If you receive "MinimumNotFoundException" errors, increasing this value may help.
      @gradient_tolerance = 1e-6

      # The parameter convergence tolerance. The minimization process will be terminated if the approximate fractional
      # change in all parameters is no greater than the parameter tolerance. Larger values allow the process to terminate when the
      # parameters are changing by a larger amount between iterations.
      @parameter_tolerance = 1e-10

      # The value convergence tolerance. The minimization process will be terminated if the fractional change in value
      # is no greater than the value tolerance. Larger values allow the process to terminate when the objective value is changing by a
      # larger amount between iterations.
      @value_tolerance = 1e-9

      # Internal variables:
      @constraints = []
      @bounds = []
    end

    def arity
      @function.arity
    end

    def check_arity(description, param_arity)
      raise "#{description} (#{param_arity}) != arity of function (#{arity})" unless param_arity == arity
    end

    # Adds a constraint to the system.
    #
    # "constraint": A function that returns the distance from the parameters to the edge of the constraints. A positive return
    # value indicates that the parameters violate the constraints, and a non-positive return value indicates that the parameters do not
    # violate the constraints. You should not merely return constant values indicating whether the constraint is violated or not, but
    # actually measure the distance to the constraint. For example, to implement the constraint x*y &gt;= 5, return 5 - x*y,
    # and to implement the constraint x*y = 5, return Math.Abs(5 - x*y).
    #
    # For simple bounds constraints, such as y &gt;= 10 or 0 &lt;= x &lt;= 5, it is usually more convenient to use
    # the "SetBounds" method, which adds the appropriate constraint automatically.
    #
    def add_constraint(constraint)
      constraint = constraint.new if constraint.kind_of?(Class)
      check_arity("arity of constraint", constraint.arity)
      @constraints << constraint
    end

    # Adds or removes a bounds constraint on a parameter.
    #
    # "parameter": The ordinal of the parameter to bound, from 0 to one less than the arity of the objective function.
    # "minimum": The minimum value of the parameter, or nil if the parameter is unbounded below.
    # "maximum": The maximum value of the parameter, or nil if the parameter is unbounded above.
    #
    # To remove a bounds constraint, use nil for the minimum and maximum.
    #
    # To set an equality constraint, pass the same value for "minimum" and "maximum". Note that
    # equality constraints are not suitable for use with interior-point "ConstraintEnforcement" methods. Setting a bound with
    # this method merely adds a constraint as though "AddConstraint" were called with a suitable constraint function. It does
    # not in itself prevent the parameter from going out of bounds (although some types of "ConstraintEnforcement" methods do).
    #
    def set_bounds(parameter, minimum, maximum)
      if minimum || maximum
        @bounds[parameter] = (minimum || -Float::INFINITY)..(maximum || Float::INFINITY)
      else
        @bounds[parameter] = nil
      end
    end

    # Locally minimizes the objective function passed to the constructor subject to the constraints that have been added.
    #
    # "guess": An initial guess for the location of the minimum. In general, a global minimum may not be found unless you can supply
    # a nearby initial point. If you cannot, then only a local minimum may be found. The initial point is not required to satisfy any
    # bounds or constraints unless "ConstraintEnforcement" is set to a barrier method.
    #
    # This method is safe to call from multiple threads simultaneously, as long as the properties of the object are not modified
    # while any minimization is ongoing. If you receive "MinimumNotFoundException" errors, try increasing the value of
    # "GradientTolerance".
    #
    def minimize(guess, stats = Stats.new)
      check_arity("dimensions of initial guess", guess.count)

      # if no constraints have been added, just minimize the function normally
      return bfgs(function, guess, stats) if @bounds.all?(&:nil?) && @constraints.empty?

      penalty_function = PenaltyFunction.new(self, @base_penalty_multiplier)

      x = guess
      value = 0.0

      100.times do |iteration|
        new_value = nil
        begin
          new_value, new_x = bfgs(penalty_function, x, stats)
        rescue NoMinimumFoundError => e
          # sometimes early on (e.g. just the first iteration or two) it will fail to find a minimum
          # but will succeed after the penalty factor ramps up. so we'll ignore those errors at first
          raise if iteration >= 10
          new_value, new_x = e.last_result
        end

        if penalty_function.last_penalty.abs <= new_value.abs * @constraint_tolerance
          return new_x
        elsif iteration > 0 && parameter_convergence(new_x, x) <= @parameter_tolerance
          return new_x
        elsif (new_value - value).abs / [1, value.abs].max <= @value_tolerance
          return new_x
        end

        value = new_value
        x = new_x

        # if we're using a barrier method, we need to decrease the penalty factor on each iteration. otherwise, we need to increase it
        penalty_function.adjust_penalty_factor(@penalty_change_factor)
      end

      raise NoMinimumFoundError.new [value, x]
    end

    include GSL::MultiMin

    def bfgs(function, x, stats)
      minimizer = FdfMinimizer.alloc(FdfMinimizer::VECTOR_BFGS, arity)

      f = proc do |x, params|
        function.evaluate(*x)
      end
      df = proc do |x, params, df|
        function.evaluate_gradient(*x).each_with_index do |v, i|
          df[i] = v
        end
      end
      fdf_func = Function_fdf.alloc(f, df, arity)
      fdf_func.set_params([])

      vector = GSL::Vector.alloc(*x)
      minimizer.set(fdf_func, vector, 0.1, 0.1)

      1000.times do
        minimizer.iterate
        stats.after_iterate(minimizer)
        status = minimizer.test_gradient(@gradient_tolerance)

        if status == GSL::SUCCESS
          return bfgs_result(minimizer)
        elsif status != GSL::CONTINUE
          raise "bad status"
        end
      end

      raise NoMinimumFoundError.new(bfgs_result(minimizer))
    end

    def bfgs_result(minimizer)
      [minimizer.f, minimizer.x.map(&:to_f).to_a]
    end

    def parameter_convergence(xs, step)
      max_value = 0.0
      xs.each_with_index do |x, i|
        value = step[i].abs / [x.abs, 1].max
        max_value = value if value > max_value
      end
      return max_value
    end
  end
end
