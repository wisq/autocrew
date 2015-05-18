require 'autocrew/coord'

module Autocrew
  class OwnShip
    def initialize(time, course, speed)
      @start  = time
      @course = course
      @speed  = speed
    end

    def location(time)
      delta = time - @start
      Coord.new(0, 0).travel(@course, @speed * delta.hours_f)
    end
  end
end
