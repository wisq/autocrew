require 'autocrew/vector'

module Autocrew
  class Coord
    include Glomp::Glompable

    attr_reader :x, :y

    def initialize(x, y)
      @x = x.to_f
      @y = y.to_f
    end

    def travel(bearing, distance)
      vector = Vector.bearing(bearing)
      self + (vector * distance)
    end

    def +(other)
      self.class.new(@x + other.x, @y + other.y)
    end

    def -(other)
      Vector.create(@x - other.x, @y - other.y)
    end

    def ==(other)
      @x == other.x && @y == other.y
    end

    def distance_squared_to(other)
      dx = other.x - @x
      dy = other.y - @y
      dx*dx + dy*dy
    end

    def to_hash
      {x: @x, y: @y}
    end

    def self.from_hash(hash)
      new(hash['x'], hash['y'])
    end

    def travel_curved(direction, init_bearing, final_bearing, distance)
      # Find fraction of circle travelled, based on bearings.
      if direction == :port
        degrees = (init_bearing - final_bearing) % 360 * -1
      else
        degrees = (final_bearing - init_bearing) % 360
      end
      circle_fraction = degrees.abs / 360.0

      # Find circle radius with circumference = distance * circle_fraction.
      radius = distance / circle_fraction / Math::PI / 2.0
      if direction == :port
        radius_bearing = (init_bearing - 90) % 360
      else
        radius_bearing = (init_bearing + 90) % 360
      end
      inverse_bearing = (radius_bearing + 180) % 360

      centre = self.travel(radius_bearing, radius)
      return centre.travel(inverse_bearing + degrees, radius)
    end
  end
end
