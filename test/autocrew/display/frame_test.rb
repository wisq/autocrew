require 'minitest_helper'
require 'autocrew/display/frame'

module Autocrew
  class Display::FrameTest < Minitest::Test
    def setup
      @state  = WorldState.new
      @window = mock
      @window.stubs(:width).returns(640)
      @window.stubs(:height).returns(480)
      @frame  = Display::Frame.new(@window, @state)
    end

    test "determine_bounds fails with no points" do
      @frame.expects(:all_locations).returns([])
      assert !@frame.determine_bounds
      assert_nil @frame.origin
      assert_nil @frame.scale_factor
    end

    test "determine_bounds finds ratio-corrected bounds of points with 10% margin at edges" do
      @frame.expects(:all_locations).returns([
        Coord.new( 20, 10),
        Coord.new(-20,-10)
      ]) # 40 wide, 20 tall; limited by width; 48 width, 36 height
      assert @frame.determine_bounds
      assert_coord -24, -18, @frame.origin
      assert_in_delta 13.33333, @frame.scale_factor
    end

    test "determine_bounds with non-zero center" do
      @frame.expects(:all_locations).returns([
        Coord.new(120,  -90),
        Coord.new( 80, -110)
      ]) # 40 wide, 20 tall; limited by width; 48 width, 36 height
      assert @frame.determine_bounds
      assert_coord 76, -118, @frame.origin
      assert_in_delta 13.33333, @frame.scale_factor
    end

    test "determine_bounds while height-limited" do
      @frame.expects(:all_locations).returns([
        Coord.new( 10, 20),
        Coord.new(-10,-20)
      ]) # 20 wide, 40 tall; limited by height; 64 width, 48 height
      assert @frame.determine_bounds
      assert_coord -32, -24, @frame.origin
      assert_in_delta 10, @frame.scale_factor
    end
  end
end
