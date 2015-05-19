require 'autocrew/coord'

module Autocrew
  class Movement
    def initialize(duration)
      @duration = duration
    end

    def apply(coord, time)
      if time < @duration
        return [coord + calculate(time), nil]
      else
        return [coord + calculate(@duration), time - @duration]
      end
    end


    class Straight < Movement
      def initialize(duration, bearing, speed)
        super(duration)
        @bearing = bearing
        @speed = speed
      end

      def calculate(time)
        Coord.new(0,0).travel(@bearing, @speed * time.hours_f)
      end
    end


    class Curved < Movement
      def initialize(duration, init_bearing, direction, final_bearing, speed)
        raise "Unknown direction: #{direction.inspect}" unless [:port, :starboard].include?(direction)
        super(duration)

        @init_bearing = init_bearing
        @direction = direction
        @final_bearing = final_bearing
        @speed = speed
      end

      def derive
        distance = @speed * @duration.hours_f
        if @direction == :port
          magnitude = (@init_bearing - @final_bearing) % 360
        else
          magnitude = (@final_bearing - @init_bearing) % 360
        end
        circle_fraction = 360.0 / magnitude

        # Find circle radius with circumference = distance * circle_fraction.
        radius = (distance * circle_fraction) / Math::PI / 2
        if @direction == :port
          radius_bearing = (@init_bearing - 90) % 360
        else
          radius_bearing = (@init_bearing + 90) % 360
        end

        @magnitude = magnitude
        @radius = radius
        @radius_bearing  = radius_bearing
        @inverse_bearing = (@radius_bearing + 180) % 360
        @centre = Coord.new(0,0).travel(radius_bearing, radius)
      end

      def calculate(time)
        derive unless @magnitude && @centre
        degrees = @magnitude * time.to_f / @duration.to_f
        degrees *= -1 if @direction == :port
        @centre.travel(@inverse_bearing + degrees, @radius)
      end
    end
  end
end
