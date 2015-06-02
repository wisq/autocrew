require 'gosu'
require 'texplay'
require 'autocrew/display'
require 'autocrew/contact'

module Autocrew
  module Display
    class Frame
      attr_reader :width, :height, :scale_factor, :origin

      BACKGROUND_COLOUR = [0.70, 0.86, 0.94, 1.0]
      DEFAULT_COLOUR = :white
      OWNSHIP_COLOUR = :red
      CONTACT_COLOUR = :blue
      LINE_THICKNESS = 3

      def initialize(window, state)
        @window = window
        @state = state
      end

      def width
        @window.width
      end

      def height
        @window.height
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

      def screen_position(coord, image = nil)
        offset = (coord - @origin) * @scale_factor
        return [offset.x, height - offset.y]
      end

      def draw_background
        image = Gosu::Image.new(TexPlay::EmptyImageStub.new(32, 32), :tileable => true)
        image.paint do
          rect 0, 0, image.width, image.height, :color => BACKGROUND_COLOUR, :fill => true
        end
        image.draw(-100, -100, 0, 100, 100)
      end

      def draw_ship(ship, coord)
        return unless ship.speed

        position = screen_position(coord)

        shape  = :square
        colour = CONTACT_COLOUR
        if ship.kind_of?(Ownship)
          shape  = :circle
          colour = OWNSHIP_COLOUR
        end

        point_image = Gosu::Image.new(TexPlay::EmptyImageStub.new(1, 1))
        point_image.paint { pixel 0, 0, :color => :black }
        point_image.draw(*position, 10)

        ship_image = Gosu::Image.new(TexPlay::EmptyImageStub.new(20, 20))
        ship_image.paint do
          if shape == :circle
            circle 9, 9, 9,   :color => colour, :fill => true
            circle 9, 9, 6.5, :color => :alpha, :fill => true
          elsif shape == :square
            rect 2, 2, 17, 17, :color => colour, :thickness => LINE_THICKNESS
          end
        end

        arrow_image = Gosu::Image.new(TexPlay::EmptyImageStub.new(15, 16))
        arrow_image.paint do
          line 0, 7,  7, 0, :color => colour, :thickness => LINE_THICKNESS
          line 7, 0, 14, 7, :color => colour, :thickness => LINE_THICKNESS
        end

        line_image = Gosu::Image.new(TexPlay::EmptyImageStub.new(4, 32))
        line_image.paint { rect 1, 0, 2, 31, :color => colour, :fill => true }

        speed_scale = ship.speed / 6.0 * @scale_factor / line_image.height

        ship_image.draw_rot(*position, 1, 0)
        line_image.draw_rot(*position, 2, ship.course, 0.5, 1, 1, speed_scale)
        arrow_image.draw_rot(*position, 3, ship.course, 0.5, line_image.height * speed_scale / arrow_image.height)
      end

      def draw
        draw_background unless BACKGROUND_COLOUR == :black

        @origin = Coord.new(0, 0)
        @scale_factor = 100.0

        ownship = Ownship.new
        ownship.add_event(Event::Initial.new(nil, 45, 10))
        draw_ship(ownship, Coord.new(3, 3))

        contact = Contact.new
        contact.course = 45
        contact.speed  = 10
        draw_ship(contact, Coord.new(4, 3))

        #return unless determine_bounds
        #draw_ownship
      end
    end
  end
end
