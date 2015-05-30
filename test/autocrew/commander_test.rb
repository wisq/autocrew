require 'minitest_helper'
require 'autocrew/commander'

module Autocrew
  class CommanderTest < Minitest::Test
    def setup
      @world = WorldState.new
      @world.ownship = @ownship = Ownship.new
      @world.contacts['s1'] = @s1 = Contact.new
    end

    test "apply new bearing report" do
      parse("at 11:00 s1 bearing 234")
      assert_equal 1, @s1.observations.count
      assert_equal 234, @s1.observations.first.bearing

      parse("at 11:10 s1 bearing 240")
      assert_equal 2, @s1.observations.count
      assert_equal 234, @s1.observations.first.bearing
      assert_equal 240, @s1.observations.last.bearing
    end

    test "create new contact with bearing report" do
      parse("at 11:00 s2 bearing 234")
      assert s2 = @world.contacts['s2']
      assert_equal 1, s2.observations.count
      assert_equal 234, s2.observations.first.bearing

      parse("at 11:10 s2 bearing 240")
      assert_equal 2, s2.observations.count
      assert_equal 234, s2.observations.first.bearing
      assert_equal 240, s2.observations.last.bearing
    end

    test "garbage at end of command" do
      assert_raises(Commander::ExtraWordsError) do
        parse("at 11:00 s1 bearing 234 garbage words")
      end
      assert_equal 0, @s1.observations.count
    end

    test "invalid bearing string" do
      assert_raises(Commander::ValueError) do
        parse("at 11:00 s1 bearing 1a2b3")
      end
      assert_equal 0, @s1.observations.count

      assert_raises(Commander::ValueError) do
        parse("at 11:00 s1 bearing 1.2.3")
      end
      assert_equal 0, @s1.observations.count
    end

    def parse(text)
      Commander.new(@world, text).parse
    end
  end
end
