require 'autocrew/solver/constrained_minimizer'
require 'autocrew/solver/range_error_function'
require 'autocrew/solver/course_normalization_constraint'

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

      def bearing_vector
        Vector.bearing(bearing)
      end
    end

    def initialize
      @observations = []
    end

    def solve
      # Initial guess:
      init_x = 0.0
      init_y = 0.0
      init_course = 135.0
      init_speed  = 6.0

      point = []
      point[0] = init_x
      point[1] = init_y
      point[4] = init_speed

      # set the initial course (normalized velocity). use the center of the course range if there is one, taking care to handle
      # ranges that span zero (e.g. 350 to 10). otherwise, use the exact course if it's given. otherwise, use the current course
      normalVelocity = Vector.bearing(init_course)
      point[2] = normalVelocity.x
      point[3] = normalVelocity.y

      minimizer = Solver::ConstrainedMinimizer.new(Solver::RangeErrorFunction.new(self))

      # Enforce non-negative speed:
      minimizer.set_bounds(2, normalVelocity.x - 0.2, normalVelocity.x + 0.2)
      minimizer.set_bounds(3, normalVelocity.y - 0.2, normalVelocity.y + 0.2)
      minimizer.set_bounds(4, 5.0, 7.0)
      #minimizer.add_constraint(Solver::CourseNormalizationConstraint5D)  # constrain the course vector to be normalized

      minimizer.minimize(point)
      p point
    end
  end
end
