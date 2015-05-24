require 'gsl'
require 'autocrew'

module Autocrew
  class Vector
    attr_reader :vector

    def self.create(x, y)
      new(GSL::Vector.alloc(x, y))
    end

    def self.deg2rad(degrees)
      degrees * Math::PI / 180
    end

    def self.bearing(degrees)
      radians = deg2rad(degrees)
      create(Math.sin(radians), Math.cos(radians))
    end

    def initialize(vector)
      @vector = vector
    end

    def x
      @vector[0]
    end

    def y
      @vector[1]
    end

    def dot_product(other)
      x*other.x + y*other.y
    end

    def cross_vector
      self.class.create(y, -x)
    end

    def *(value)
      self.class.new(@vector.mul(value))
    end

    def inspect
      "#<#{self.class} x=#{x} y=#{y}>"
    end
  end
end
