require 'minitest_helper'
require 'autocrew/display/frame'

module Autocrew
  class Display::FrameTest < Minitest::Test
    def setup
      @state  = WorldState.new
      @window = Display::Frame.new(@state, 640, 480)
    end

    test "determine_bounds fails with no points" do
      @state.expects(:display_points).returns([])
      assert !@window.determine_bounds
      assert_nil @window.origin
      assert_nil @window.scale_factor
    end

    test "determine_bounds finds ratio-corrected bounds of points with 10% margin at edges" do
      @state.expects(:display_points).returns([
        Coord.new( 20, 10),
        Coord.new(-20,-10)
      ]) # 40 wide, 20 tall; limited by width; 48 width, 36 height
      assert @window.determine_bounds
      assert_coord -24, -18, @window.origin
      assert_in_delta 13.33333, @window.scale_factor
    end

    test "determine_bounds with non-zero center" do
      @state.expects(:display_points).returns([
        Coord.new(120,  -90),
        Coord.new( 80, -110)
      ]) # 40 wide, 20 tall; limited by width; 48 width, 36 height
      assert @window.determine_bounds
      assert_coord 76, -118, @window.origin
      assert_in_delta 13.33333, @window.scale_factor
    end

    test "determine_bounds while height-limited" do
      @state.expects(:display_points).returns([
        Coord.new( 10, 20),
        Coord.new(-10,-20)
      ]) # 20 wide, 40 tall; limited by height; 64 width, 48 height
      assert @window.determine_bounds
      assert_coord -32, -24, @window.origin
      assert_in_delta 10, @window.scale_factor
    end
  end
end
