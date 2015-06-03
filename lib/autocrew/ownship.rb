require 'autocrew/coord'

module Autocrew
  class Ownship
    include Glomp::Glompable

    attr_reader :events

    def initialize(events = [])
      @events = events
      @events.sort_by!(&:game_time)
    end

    def add_event(event)
      @events << event
      @events.sort_by!(&:game_time)
    end

    def to_hash
      return {
        'events' => @events,
      }
    end

    def self.from_hash(hash)
      new(hash['events'])
    end

    def initial_time
      return nil if @events.empty?
      return @events.first.game_time
    end

    def distance_between(start_time, stop_time)
      speed = @events.first.speed  # FIXME support changing speed after initial
      return speed * (stop_time - start_time).hours_f
    end

    def speed
      return @events.first.speed  # FIXME support changing speed after initial
    end

    def location(at_time)
      loc, _ = location_and_course(at_time)
      return loc
    end

    def location_and_course(at_time)
      loc = Coord.new(0,0)

      initial   = @events.first
      course    = initial.course
      last_time = initial.game_time
      return if at_time < last_time
      turn_dir  = nil

      done = false
      @events.each_with_index do |event, index|
        if index == 0 # initial event
          last_time = event.game_time
          next
        end

        end_time = event.game_time
        time_portion = 1.0
        if end_time >= at_time
          time_portion = (at_time - last_time).to_f / (end_time - last_time).to_f
          end_time = at_time
          done = true
        end

        if event.begin_turn?
          loc = loc.travel(course, distance_between(last_time, end_time))
          turn_dir = event.turn_direction
          last_time = event.game_time
        elsif event.respond_to?(:new_course)
          new_course = event.new_course
          if time_portion < 1.0
            if turn_dir == :starboard
              new_course = course + (new_course - course)*time_portion
            else
              new_course = course - (course - new_course)*time_portion
            end
          end

          loc = loc.travel_curved(turn_dir, course, new_course, distance_between(last_time, end_time))
          last_time = event.game_time
          course = new_course
        end

        break if done
      end

      loc = loc.travel(course, distance_between(last_time, at_time)) unless done
      return [loc, course]
    end
  end
end
