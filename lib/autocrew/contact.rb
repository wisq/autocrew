require 'autocrew/solver/constrained_minimizer'
require 'autocrew/solver/range_error_function'
require 'autocrew/solver/course_normalization_constraint'

module Autocrew
  class Contact
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

    attr_accessor :origin, :course, :speed, :observations

    def initialize
      @observations = []
    end

    def origin_time
      @observations.first.game_time
    end

    def solve
      normal_velocity = Vector.bearing(@course.to_f)
      origin = @origin || Coord.new(0, 0)
      point = [
        origin.x,
        origin.y,
        normal_velocity.x,
        normal_velocity.y,
        @speed.to_f,
      ]

      @observations.sort_by!(&:game_time)
      minimizer = Solver::ConstrainedMinimizer.new(Solver::RangeErrorFunction.new(self))

      minimizer.set_bounds(4, 0, Float::INFINITY)  # enforce non-negative speed
      minimizer.add_constraint(Solver::CourseNormalizationConstraint5D)  # constrain the course vector to be normalized

      stats = Solver::ConstrainedMinimizer::Stats.new
      pos_x, pos_y, nvel_x, nvel_y, speed = minimizer.minimize(point, stats)

      @origin = Coord.new(pos_x, pos_y)
      @course = Vector.create(nvel_x, nvel_y).bearing
      @speed  = speed

      return stats
    end
  end
end
