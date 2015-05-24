require 'autocrew/solver'

module Autocrew::Solver
  class CourseNormalizationConstraint4D
    def arity
      return 4
    end

    def derivative_count
      return 1
    end

    def evaluate(_, _, nvel_x, nvel_y)
      return (nvel_x**2 + nvel_y**2 - 1).abs
    end

    def evaluate_gradient(_, _, nvel_x, nvel_y)
      if nvel_x**2 + nvel_y**2 < 1
        nvel_x *= -1
        nvel_y *= -1
      end

      return [0.0, 0.0, 2*nvel_x, 2*nvel_y]
    end
  end

  class CourseNormalizationConstraint5D < CourseNormalizationConstraint4D
    def arity
      return 5
    end

    def derivative_count
      return 1
    end

    def evaluate(_, _, nvel_x, nvel_y, _)
      return super(nil, nil, nvel_x, nvel_y)
    end

    def evaluate_gradient(_, _, nvel_x, nvel_y, _)
      return super(nil, nil, nvel_x, nvel_y) + [0.0]
    end
  end
end
