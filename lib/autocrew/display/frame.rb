require 'gosu'
require 'texplay'
require 'autocrew/display'
require 'autocrew/contact'

module Autocrew
  module Display
    class Frame
      attr_reader :width, :height, :scale_factor, :origin

      BACKGROUND_COLOUR = [0.70, 0.86, 0.94, 1.0]
      DEFAULT_COLOUR = :black
      OWNSHIP_COLOUR = :red
      CONTACT_COLOUR = :blue
      OBSERVATION_COLOUR = [0, 0, 0, 0.3]
      LINE_THICKNESS = 3
      OBSERVATION_THICKNESS = 1

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

      def all_locations
        return @ownship_locations.values + @contact_locations.flatten
      end

      def determine_bounds
        points = all_locations
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

      def offscreen?(coord)
        x, y = screen_position(coord)
        return true if x < 0 || x > width
        return true if y < 0 || y > height
        return false
      end

      def draw_background
        image = Gosu::Image.new(TexPlay::EmptyImageStub.new(32, 32), :tileable => true)
        image.paint do
          rect 0, 0, image.width, image.height, :color => BACKGROUND_COLOUR, :fill => true
        end
        image.draw(-100, -100, 0, 100, 100)
      end

      def draw_ship(ship, location, course)
        return unless ship.speed && location

        position = screen_position(location)

        shape  = :square
        colour = CONTACT_COLOUR
        if ship.kind_of?(Ownship)
          shape  = :circle
          colour = OWNSHIP_COLOUR
        end

        point_image = Gosu::Image.new(TexPlay::EmptyImageStub.new(1, 1))
        point_image.paint { pixel 0, 0, :color => :black }
        point_image.draw(*position, 10)

        params = {:color => colour, :thickness => LINE_THICKNESS}
        ship_image = shape(shape, params)
        arrow_image = shape(:arrowhead, params)
        line_image = shape(:line, params)

        speed_scale = speed_arrow_length(ship.speed) / arrow_image.height / 2

        ship_image.draw_rot(*position, 3, 0)
        line_image.draw_rot(*position, 2, course, 0.5, 1, 1, speed_scale)
        arrow_image.draw_rot(*position, 3, course, 0.5, line_image.height * speed_scale / arrow_image.height)
      end

      def time_horizon
        return @now - GameTime.parse("01:00") # FIXME option set on contact?
      end

      def speed_arrow_length(speed)
        return speed * 10  # pixels
      end

      def trace_ownship
        ownship = @state.ownship

        min_time = [ownship.initial_time, time_horizon].max
        @ownship_locations = {}
        [@now, min_time].each do |time|
          loc = ownship.location(time)
          @ownship_locations[time] = loc if loc
        end

        step = GameTime.parse("00:00:05")
        time = @now.floor(step)
        bounds_determined = false

        loop do
          loc = ownship.location(time)
          break if loc.nil?

          @ownship_locations[time] = loc

          time = time - step

          if bounds_determined
            break if offscreen?(loc)
          elsif time <= min_time
            determine_bounds
            bounds_determined = true
          end
        end

        determine_bounds unless bounds_determined
      end

      def active_contacts
        focused = @state.focused_contact
        return {@state.focus => focused} if focused
        return @state.contacts
      end

      def trace_contacts
        @contact_locations = []

        active_contacts.each do |id, contact|
          init_time = contact.initial_time
          next if init_time.nil?
          min_time = [init_time, time_horizon].max
          max_time = @now

          locations = [min_time, max_time].map { |t| contact.location(t) }.compact

          if locations.count == 2
            @contact_locations << locations
          end
        end
      end

      def draw_ownship
        ownship = @state.ownship
        location, course = ownship.location_and_course(@now)
        draw_ship(@state.ownship, location, course)

        last_loc = nil
        @ownship_locations.sort.each do |_, loc|
          draw_line(last_loc, loc) unless last_loc.nil?
          last_loc = loc
        end
      end

      def draw_contacts
        ownship = @state.ownship
        active_contacts.each do |id, contact|
          draw_ship(contact, contact.location(@now), contact.course)

          contact.observations.each do |obs|
            next if obs.game_time > @now
            loc = obs.observer.location(obs.game_time)
            next unless loc
            target = loc.travel(obs.bearing, 100)
            draw_line(loc, target, 1, OBSERVATION_COLOUR, OBSERVATION_THICKNESS)
          end
        end

        @contact_locations.each do |coord1, coord2|
          draw_line(coord1, coord2)
        end
      end


      def shape(*args)
        return @window.shape_cache[args] ||= make_shape_image(*args)
      end

      def make_shape_image(shape, params)
        image = nil
        if shape == :arrowhead
          image = Gosu::Image.new(TexPlay::EmptyImageStub.new(15, 16))
          image.paint do
            line 0, 7,  7, 0, params
            line 7, 0, 14, 7, params
          end
        elsif shape == :line
          thickness = params[:thickness] || LINE_THICKNESS
          image = Gosu::Image.new(TexPlay::EmptyImageStub.new(thickness + 1, 32))
          image.paint { rect 1, 0, thickness - 1, 31, params.merge(:fill => true) }
        elsif shape == :circle
          image = Gosu::Image.new(TexPlay::EmptyImageStub.new(20, 20))
          image.paint do
            circle 9, 9, 9,   params.merge(:fill => true)
            circle 9, 9, 6.5, params.merge(:color => :alpha, :fill => true)
          end
        elsif shape == :square
          image = Gosu::Image.new(TexPlay::EmptyImageStub.new(20, 20))
          image.paint do
            rect 2, 2, 17, 17, params
          end
        else
          raise "Unknown shape: #{shape.inspect}"
        end
        return image
      end

      def draw_line(coord1, coord2, z = 1, colour = DEFAULT_COLOUR, thickness = LINE_THICKNESS)
        image = shape(:line, :color => colour, :thickness => thickness)

        vector = coord2 - coord1
        angle  = vector.bearing % 360
        scale  = vector.magnitude * @scale_factor / image.height
        image.draw_rot(*screen_position(coord1), z, angle, 0.5, 1, 1, scale)
      end

      def draw
        draw_background unless BACKGROUND_COLOUR == :black

        @origin = Coord.new(0, 0)
        @scale_factor = 100.0

        return unless @state.stopwatch
        @now = @state.stopwatch.now

        return unless @state.ownship
        trace_contacts
        trace_ownship

        draw_ownship
        draw_contacts
      end
    end
  end
end
