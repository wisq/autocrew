require 'gosu'
require 'autocrew/display/frame'

module Autocrew
  module Display
    class Window < Gosu::Window
      attr_accessor :shape_cache

      def initialize(state)
        super(1280, 720, false)
        self.caption = "Autocrew"

        @state = state
        @next_redraw = Time.now
        @fps = 0
        @shape_cache = {}
      end

      def needs_redraw?
        return Time.now > @next_redraw
      end

      def draw
        frame = Frame.new(self, @state)
        image = frame.draw

        @next_redraw = Time.now + 0.5
        return super
      rescue Exception => e
        puts "Error in draw: #{e}"
        e.backtrace.take(3).each do |bt|
          puts "  #{bt}"
        end
        @next_redraw = Time.now + 3.0
      end
    end
  end
end
