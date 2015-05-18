require 'minitest_helper'
require 'autocrew/stopwatch'

module Autocrew
  class StopwatchTest < Minitest::Test
    test "tells the current game time" do
      gtime = GameTime.from_values(1, 2, 3, 4.5)
      watch = Stopwatch.new(gtime)
      assert_in_delta gtime.to_f, watch.now.to_f
    end

    test "offsets the game time based on real time delta" do
      gtime = GameTime.from_values(1, 2, 3, 4.5)
      watch = Stopwatch.new(gtime, Time.now - 86523) # + 1 day, 2 minutes, 3 seconds
      now = watch.now

      assert_equal 2, now.day
      assert_equal 2, now.hour
      assert_equal 5, now.minute
      assert_in_delta 7.5, now.second
    end
  end
end
