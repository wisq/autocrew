require 'gsl'
require 'autocrew'

module Autocrew
  class Vector
    attr_reader :x, :y

    def self.deg2rad(degrees)
      degrees * Math::PI / 180
    end

    def self.rad2deg(degrees)
      degrees * 180 / Math::PI
    end

    def self.bearing(degrees)
      radians = deg2rad(degrees)
      new(Math.sin(radians), Math.cos(radians))
    end

    def initialize(x, y)
      @x = x
      @y = y
    end

    def dot_product(other)
      x*other.x + y*other.y
    end

    def cross_vector
      self.class.new(y, -x)
    end

    def *(value)
      self.class.new(x*value, y*value)
    end

    def /(value)
      self * (1.0 / value)
    end

    def bearing
      Vector.rad2deg(Math.atan2(x, y))
    end

    def magnitude
      Math.sqrt(x**2 + y**2)
    end

    def normal
      self / magnitude
    end

    def inspect
      "#<#{self.class} x=#{x} y=#{y}>"
    end
  end
end
