require 'gosu'
require 'texplay'
require 'autocrew/display'

module Autocrew
  module Display
    class Frame
      attr_reader :width, :height, :scale_factor, :origin

      def initialize(state, width, height)
        @state  = state
        @width  = width
        @height = height
      end

      def determine_bounds
        points = @state.display_points
        return if points.empty?

        xs = points.map(&:x)
        ys = points.map(&:y)
        raw_width  = xs.max - xs.min
        raw_height = ys.max - ys.min
        center_x = xs.min + raw_width/2.0
        center_y = ys.min + raw_height/2.0

        aspect_ratio = self.width.to_f / self.height.to_f
        if raw_width / raw_height > aspect_ratio
          # width is limiting factor
          desired_width  = 1.2 * raw_width
          desired_height = 1.2 * (raw_width / aspect_ratio)
        else
          # height is limiting factor
          desired_height = 1.2 * raw_height
          desired_width  = 1.2 * (raw_height * aspect_ratio)
        end

        @scale_factor = self.width / desired_width
        @origin = Coord.new(
          center_x - (desired_width / 2),
          center_y - (desired_height / 2),
        )
      end

      def position(coord)
        offset = (@coord - @origin) * @scale_factor
        return [offset.x, offset.y]
      end

      def draw_background
        width  = @width
        height = @height
        @image.paint do
          rect 0, 0, width, height, :color => [0.70, 0.86, 0.94, 1.0], :fill => true
        end
      end

      def draw_ownship
        return unless @state.stopwatch && @state.ownship
        now = @state.stopwatch.now
        @image.paint do
          location = @state.ownship.location(now)
          circle(*position(coord), 20)
        end
      end

      def draw(window)
        @image = Gosu::Image.new(TexPlay::EmptyImageStub.new(@width, @height))
        draw_background
        draw_ownship
        @image.draw(0, 0, 0)
      end
    end
  end
end
