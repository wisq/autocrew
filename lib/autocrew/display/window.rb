require 'rubygame'
require 'autocrew/display/frame'

module Autocrew
  module Display
    class Window
      def initialize(state)
        @state = state
        @screen = Rubygame::Screen.new([1280,720])
        @screen.title = "Autocrew"
      end

      def loop
        loop { one_loop }
      end

      def one_loop
        frame = Frame.new(self, @state)
        image = frame.draw

        sleep(0.5)
      rescue Exception => e
        puts "Error in draw: #{e}"
        e.backtrace.take(3).each do |bt|
          puts "  #{bt}"
        end
        sleep(3)
      end
    end
  end
end
