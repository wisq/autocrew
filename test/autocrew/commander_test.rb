require 'minitest_helper'
require 'autocrew/commander'

module Autocrew
  class CommanderTest < Minitest::Test
    def setup
      @world = WorldState.new
      @world.ownship = @ownship = Ownship.new
      @world.contacts['s1'] = @s1 = Contact.new
      @commander = Commander.new
    end

    test "apply new bearing report" do
      command("at 11:00 s1 bearing 234")
      assert_equal 1, @s1.observations.count
      assert_equal 234, @s1.observations.first.bearing

      command("at 11:10 s1 bearing 240")
      assert_equal 2, @s1.observations.count
      assert_equal 234, @s1.observations.first.bearing
      assert_equal 240, @s1.observations.last.bearing
    end

    test "create new contact with bearing report" do
      command("at 11:00 s2 bearing 234")
      assert s2 = @world.contacts['s2']
      assert_equal 1, s2.observations.count
      assert_equal 234, s2.observations.first.bearing

      command("at 11:10 s2 bearing 240")
      assert_equal 2, s2.observations.count
      assert_equal 234, s2.observations.first.bearing
      assert_equal 240, s2.observations.last.bearing
    end

    test "unknown command" do
      assert_raises(Commander::UnknownCommandError) do
        command("foooooo")
      end
    end

    test "invalid bearing string" do
      assert_raises(Commander::ValueError) do
        command("at 11:00 s1 bearing 1a2b3")
      end
      assert_equal 0, @s1.observations.count

      assert_raises(Commander::ValueError) do
        command("at 11:00 s1 bearing 1.2.3")
      end
      assert_equal 0, @s1.observations.count
    end

    test "timeless observation uses stopwatch time" do
      @world.stopwatch = stopwatch = mock

      stopwatch.expects(:now).returns(time1 = GameTime.parse("23:00"))
      command("s1 bearing 234")
      assert_equal 1, @s1.observations.count
      assert_equal time1, @s1.observations.first.game_time

      stopwatch.expects(:now).returns(time2 = GameTime.parse("23:10"))
      command("s1 bearing 240")
      assert_equal 2, @s1.observations.count
      assert_equal time2, @s1.observations.last.game_time
    end

    test "sync stopwatch" do
      assert_nil @world.stopwatch

      command("sync 22:00")
      assert @world.stopwatch
      assert_in_delta GameTime.parse("22:00").to_f, @world.stopwatch.now.to_f

      command("sync 22:30")
      assert @world.stopwatch
      assert_in_delta GameTime.parse("22:30").to_f, @world.stopwatch.now.to_f
    end

    test "initialise ownship" do
      @world = WorldState.new
      assert_nil @world.ownship

      command("at 10:00 ownship course 123 speed 5")

      assert @ownship = @world.ownship
      assert_equal 1, @ownship.events.count
      assert_kind_of Event::Initial, event = @ownship.events.first

      assert_equal GameTime.parse("10:00"), event.game_time
      assert_equal 123, event.course
      assert_equal 5, event.speed
    end

    test "restart" do
      assert_kind_of Commander::RestartCommand, parse("restart")
    end

    test "focus" do
      @world.focus = nil
      command "s1 focus"
      assert_equal "s1", @world.focus

      @world.focus = nil
      command "s1"
      assert_equal "s1", @world.focus
    end

    def parse(text)
      @commander.parse(text)
    end

    def command(text)
      parse(text).execute(@world)
    end
  end
end
