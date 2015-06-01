require 'gosu'
require 'autocrew/display/frame'

module Autocrew
  module Display
    class Window < Gosu::Window
      def initialize(state)
        super(640, 480, false)
        self.caption = "Autocrew"

        @state = state
        @next_redraw = Time.now
        @fps = 0
      end

      def needs_redraw?
        return Time.now > @next_redraw
      end

      def draw
        frame = Frame.new(@state, self.width, self.height)
        image = frame.draw(self)

        @next_redraw = Time.now + 0.5
        return super
      rescue Exception => e
        puts "Error in draw: #{e}"
        puts "  (at #{e.backtrace.first})"
        @next_redraw = Time.now + 3.0
      end
    end
  end
end
