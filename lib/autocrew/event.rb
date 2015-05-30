require 'autocrew'

module Autocrew
  class Event
    include Glomp::Glompable

    attr_reader :game_time

    def initialize(time)
      @game_time = time
    end

    def begin_turn?
      false
    end


    class Initial < Event
      attr_reader :course, :speed

      def initialize(time, course, speed)
        super(time)
        @course = course
        @speed = speed
      end

      def to_hash
        return {
          'game_time' => @game_time,
          'course' => @course,
          'speed' => @speed,
        }
      end

      def self.from_hash(hash)
        return new(hash['game_time'], hash['course'], hash['speed'])
      end
    end


    class BeginTurn < Event
      attr_reader :direction, :course

      def initialize(time, direction, course = nil)
        raise "Unknown direction: #{direction.inspect}" unless [:port, :starboard].include?(direction)
        super(time)
        @course = course
        @direction = direction
      end

      def begin_turn?
        true
      end

      def turn_direction
        @direction
      end

      def to_hash
        return {
          'game_time' => @game_time,
          'direction' => @direction.to_s,
          'course'    => @course,
        }
      end

      def self.from_hash(hash)
        return new(hash['game_time'], hash['direction'].to_sym, hash['course'])
      end
    end


    class EndTurn < Event
      attr_reader :course

      def initialize(time, course)
        super(time)
        @course = course
      end

      def new_course
        @course
      end

      def to_hash
        return {
          'game_time' => @game_time,
          'course'    => @course,
        }
      end

      def self.from_hash(hash)
        return new(hash['game_time'], hash['course'])
      end
    end
  end
end
