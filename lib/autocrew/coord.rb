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
  end
end
