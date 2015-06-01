require 'gosu'
require 'autocrew/display'

module Autocrew
  module Display
    class Window < Gosu::Window
      def initialize(state)
        super(640, 480, false)
        self.caption = "Autocrew"

        @state = state
        @last_redraw = Time.at(0)
        @fps = 0
      end

      def needs_redraw?
        return (Time.now - @last_redraw) >= 0.5
      end

      def update
        return unless needs_redraw?
      end

      def draw
        @last_redraw = Time.now
        super
      end
    end
  end
end
