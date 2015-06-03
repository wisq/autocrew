require 'minitest_helper'
require 'autocrew/game_time'

module Autocrew
  class GameTimeTest < Minitest::Test
    USEC = 0.000001

    test "create using from_values" do
      time = GameTime.from_values(1, 2, 3, 4.5)
      assert_equal 1, time.day
      assert_equal 2, time.hour
      assert_equal 3, time.minute
      assert_equal 4.5, time.second
    end

    test "equality of two GameTimes" do
      time1 = GameTime.from_values(1, 2, 3, 4.5)
      time2 = GameTime.from_values(1, 2, 3, 4.5)
      assert_equal time1, time2
      assert time1.eql?(time2)
    end

    test "add two GameTimes" do
      time1 = GameTime.from_values(1, 23, 45, 6.78)
      time2 = GameTime.from_values(9, 10, 11, 12.13)
      assert_equal GameTime.from_values(11, 9, 56, 18.91), time1 + time2
    end

    test "create using parse" do
      assert_equal GameTime.from_values(1, 2, 3, 4.5), GameTime.parse("1d 02:03:04.5")
      assert_equal GameTime.from_values(1, 2, 3, 4.5), GameTime.parse("1d02:03:04.5")
      assert_equal GameTime.from_values(1, 2, 3, 4.5), GameTime.parse("1+02:03:04.5")
      assert_equal GameTime.from_values(0, 12, 34, 00), GameTime.parse("12:34")
      assert_equal GameTime.from_values(0, 12, 34, 56), GameTime.parse("12:34:56")
      assert_equal GameTime.from_values(3, 12, 34, 56.789), GameTime.parse("3d 12:34:56.789")
    end

    test "parse failure" do
      assert_raises(RuntimeError) { GameTime.parse("foo") }
      assert_raises(RuntimeError) { GameTime.parse("1d") }
      assert_raises(RuntimeError) { GameTime.parse("42") }
    end

    test "hours_f returns decimal hours" do
      assert_in_delta 26.05125, GameTime.from_values(1, 2, 3, 4.5).hours_f
      assert_in_delta 12.58222, GameTime.from_values(0, 12, 34, 56).hours_f
    end

    test "subtract two GameTimes" do
      time1 = GameTime.from_values(9, 10, 11, 12.13)
      time2 = GameTime.from_values(1, 23, 45, 6.78)
      assert_equal GameTime.from_values(7, 10, 26, 5.35), time1 - time2
    end

    test "compare two GameTimes" do
      time1 = GameTime.from_values(1, 23, 45, 6.78)
      time2 = GameTime.from_values(9, 10, 11, 12.13)
      assert time1 < time2
      assert time2 > time1

      assert time1 <= time2
      assert time2 >= time1

      assert time1 <= time1
      assert time2 >= time2

      assert (time1 <=> time2) < 0
      assert (time2 <=> time1) > 0
      assert_equal 0, (time1 <=> time1)
      assert_equal 0, (time2 <=> time2)
    end

    test "can be sorted" do
      time1 = GameTime.from_values(0, 0, 0, 1)
      time2 = GameTime.from_values(0, 0, 0, 2)
      time3 = GameTime.from_values(0, 0, 0, 3)

      assert_equal [time1, time2, time3], [time1, time3, time2].sort
      assert_equal [time1, time2, time3], [time2, time3, time1].sort
      assert_equal [time1, time2, time3], [time2, time1, time3].sort
      assert_equal [time1, time2, time3], [time3, time2, time1].sort
    end

    test "hashes correctly" do
      time1 = GameTime.from_values(1, 2, 3, 4.5)
      time2 = GameTime.from_values(1, 2, 3, 4.5)
      assert_equal time1.hash, time2.hash

      hash = {time1 => 1, time2 => 2}
      assert_equal 1, hash.count
    end

    test "glomp and unglomp" do
      time1 = GameTime.parse('11d 22:33:44')
      time2 = Glomp.unglomp(Glomp.glomp(time1))
      assert_equal time1, time2
    end

  end
end
