require 'autocrew/vector'
require 'autocrew/coord'

module Autocrew
  class Line
    attr_reader :start, :vector

    def initialize(start, vector_or_end)
      @start = start
      if vector_or_end.kind_of?(Vector)
        @vector = vector_or_end
        @end = start + vector
      elsif vector_or_end.kind_of?(Coord)
        @end = vector_or_end
        @vector = vector_or_end - start
      else
        raise "unknown type: #{vector_or_end.class}"
      end
    end

    def distance_to(coord)
      @vector.cross_vector.normal.dot_product(coord - @start)
    end
  end
end
