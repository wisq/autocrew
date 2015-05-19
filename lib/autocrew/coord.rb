require 'autocrew'

module Autocrew
  class Coord
    attr_reader :x, :y

    def initialize(x, y)
      @x = x
      @y = y
    end

    # FIXME move this to a better class
    def self.deg2rad(degrees)
      degrees * Math::PI / 180
    end

    def travel(bearing, distance)
      radians = self.class.deg2rad(bearing)
      new_x = @x + Math.sin(radians) * distance
      new_y = @y + Math.cos(radians) * distance
      self.class.new(new_x, new_y)
    end

    def +(other)
      self.class.new(@x + other.x, @y + other.y)
    end

    def ==(other)
      @x == other.x && @y == other.y
    end
  end
end
