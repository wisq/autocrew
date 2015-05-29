require 'autocrew'

module Autocrew
  class Event
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
    end


    class BeginTurn < Event
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
    end


    class EndTurn < Event
      def initialize(time, course)
        super(time)
        @course = course
      end

      def new_course
        @course
      end
    end
  end
end
