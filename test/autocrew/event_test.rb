require 'minitest_helper'
require 'autocrew/event'

module Autocrew
  class InitialEventTest < Minitest::Test
    test "glomp and unglomp" do
      event = Event::Initial.new(GameTime.parse("10:00"), 90, 5)

      json = Glomp.glomp(event)
      event = Glomp.unglomp(json)

      assert_equal GameTime.parse("10:00"), event.game_time
      assert_equal 90, event.course
      assert_equal 5, event.speed
    end
  end
end
