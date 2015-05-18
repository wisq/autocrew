require 'minitest_helper'
require 'autocrew/ownship'

module Autocrew
  class OwnShipTest < Minitest::Test
    def setup
      @start = GameTime.parse("10:30")
      @ownship = OwnShip.new(@start, 90, 6) # 6 knots due east
    end

    test "initial location is (0,0)" do
      loc = @ownship.location(@start)
      assert_in_delta 0.0, loc.x
      assert_in_delta 0.0, loc.y
    end

    test "location after 10 minutes is 1 nautical mile due east" do
      ten = GameTime.parse("00:10")
      loc = @ownship.location(@start + ten)
      assert_in_delta 1.0, loc.x
      assert_in_delta 0.0, loc.y
    end
  end
end
