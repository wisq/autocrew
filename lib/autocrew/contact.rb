require 'autocrew/solver/range_error_function'

module Autocrew
  class Contact
    attr_reader :observations

    class Observation
      attr_reader :observer, :game_time, :bearing

      def initialize(observer, game_time, bearing)
        @observer = observer
        @game_time = game_time
        @bearing = bearing
      end
    end

    def initialize
      @observations = []
    end

    def solve
      # Initial guess:
      point = [
        0, 0,  # position
        0, 0,  # velocity
        5      # speed
      ]

      minimizer = Autocrew::Solver::ConstrainedMinimizer.new(RangeErrorFunction.new(self))

      # Enforce non-negative speed:
      minimizer.set_bounds(4, 0, Float::INFINITY)
      minimizer.add_constraint(NormalizationConstraint.new(5))  # constrain the course vector to be normalized

      minimizer.minimize(point)
      p point
    end
  end
end
