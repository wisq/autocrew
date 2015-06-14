require 'minitest_helper'
require 'autocrew/line'

module Autocrew
  class LineTest < Minitest::Test
    test "create from coords" do
      line = Line.new(start = Coord.new(-1,2), Coord.new(2, -2))
      assert_equal start, line.start
      assert_equal  3, line.vector.x
      assert_equal -4, line.vector.y
      assert_in_delta 5, line.vector.magnitude
    end

    test "create from vector" do
      line = Line.new(start = Coord.new(-4,-1), vector = Vector.create(4, -3))
      assert_equal start, line.start
      assert_equal vector, line.vector
    end
  end
end
