require 'autocrew/solver/constrained_minimizer'
require 'autocrew/solver/range_error_function'
require 'autocrew/solver/course_normalization_constraint'

module Autocrew
  class Contact
    class Observation
      include Glomp::Glompable

      attr_reader :observer, :game_time, :bearing

      def initialize(observer, game_time, bearing)
        @observer = observer
        @game_time = game_time
        @bearing = bearing
      end

      def bearing_vector
        Vector.bearing(bearing)
      end

      def to_hash
        return {
          'observer'  => observer,
          'game_time' => game_time,
          'bearing'   => bearing,
        }
      end

      def self.from_hash(hash)
        new(
          hash['observer'],
          hash['game_time'],
          hash['bearing'],
        )
      end
    end

    include Glomp::Glompable

    attr_accessor :origin, :origin_time, :course, :speed, :observations

    def initialize
      @observations = []
    end

    def location(time)
      return nil unless @origin && @origin_time && @course
      return @origin.travel(@course, (time - @origin_time).hours_f * @speed)
    end

    def initial_time
      return @origin_time if @origin_time
      return nil if @observations.empty?
      @observations.first.game_time
    end

    def add_observation(observer, game_time, bearing)
      @observations << Observation.new(observer, game_time, bearing)
      @observations.sort_by!(&:game_time)
    end

    def solve
      return unless @observations.count >= 2

      normal_velocity = Vector.bearing(@course.to_f)
      origin = @origin || Coord.new(0, 0)
      point = [
        origin.x,
        origin.y,
        normal_velocity.x,
        normal_velocity.y,
        @speed.to_f,
      ]

      @origin_time = @observations.first.game_time

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

    def to_hash
      return {
        'origin': origin,
        'origin_time': origin_time,
        'course': course,
        'speed':  speed,
        'observations': observations,
      }
    end

    def self.from_hash(hash)
      contact = new
      contact.origin = hash['origin']
      contact.origin_time = hash['origin_time']
      contact.course = hash['course']
      contact.speed  = hash['speed']
      contact.observations = hash['observations']
      contact
    end
  end
end
