require 'gosu'
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
    end
  end
end
