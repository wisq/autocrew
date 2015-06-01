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

    test "glomp and unglomp" do
      stopwatch = Stopwatch.new(game_time = GameTime.parse("11:30"), real_time = Time.now)
      now = stopwatch.now

      json = Glomp.glomp(stopwatch)
      stopwatch = Glomp.unglomp(json)

      assert_equal game_time, stopwatch.game_time
      assert_equal real_time.to_f, stopwatch.real_time.to_f
      assert_kind_of Time, stopwatch.real_time
      assert_in_delta now.to_f, stopwatch.now.to_f
    end
  end
end
