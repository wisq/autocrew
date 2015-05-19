require 'autocrew/coord'

module Autocrew
  class OwnShip
    attr_reader :movements

    def initialize(start_time)
      @start_time = start_time
      @movements = []
    end

    def location(time)
      offset = time - @start_time
      return if offset < 0

      coord = Coord.new(0, 0)
      @movements.each do |movement|
        coord, offset = movement.apply(coord, offset)
        return coord if offset.nil?
      end

      raise "reached end of movement list"
    end
  end
end
