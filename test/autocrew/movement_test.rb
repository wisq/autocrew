require 'minitest_helper'
require 'autocrew/movement'

module Autocrew
  class MovementTest < Minitest::Test
    def assert_coord(x, y, coord, delta=0.001)
      assert_in_delta x, coord.x, delta, "Mismatch (X) between #{[x,y]} and #{[coord.x,coord.y]}"
      assert_in_delta y, coord.y, delta, "Mismatch (Y) between #{[x,y]} and #{[coord.x,coord.y]}"
    end

    class StraightMovementTest < MovementTest
      test "straight movement in cardinal directions" do
        duration = GameTime.parse("01:00")
        assert_coord   0,  10, Movement::Straight.new(duration,   0, 10).calculate(duration)
        assert_coord  10,   0, Movement::Straight.new(duration,  90, 10).calculate(duration)
        assert_coord   0, -10, Movement::Straight.new(duration, 180, 10).calculate(duration)
        assert_coord -10,   0, Movement::Straight.new(duration, 270, 10).calculate(duration)
      end

      test "straight movement in intermediate directions" do
        duration = GameTime.parse("01:30")
        assert_coord  10.6066,  10.6066, Movement::Straight.new(duration,  45, 10).calculate(duration)
        assert_coord  10.6066, -10.6066, Movement::Straight.new(duration, 135, 10).calculate(duration)
        assert_coord -10.6066, -10.6066, Movement::Straight.new(duration, 225, 10).calculate(duration)
        assert_coord -10.6066,  10.6066, Movement::Straight.new(duration, 315, 10).calculate(duration)
      end
    end

    class CurvedMovementTest < MovementTest
      test "curved port movement from 90 to 0" do
        duration = GameTime.parse("01:00")
        movement = Movement::Curved.new(duration, 90, :port, 0, 10)
        assert_coord 6.36619, 6.36619, movement.calculate(duration)
      end

      test "curved starboard movement from 90 to 180" do
        duration = GameTime.parse("01:00")
        movement = Movement::Curved.new(duration, 90, :starboard, 180, 10)
        assert_coord 6.36619, -6.36619, movement.calculate(duration)
      end

      test "half-duration curved starboard movement from 0 to 30" do
        movement = Movement::Curved.new(GameTime.parse("01:00"), 0, :starboard, 30, 10)
        assert_coord 0.65076, 4.94307, movement.calculate(GameTime.parse("00:30"))
      end
    end
  end
end
