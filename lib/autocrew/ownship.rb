require 'autocrew/coord'

module Autocrew
  class Ownship
    include Glomp::Glompable

    def initialize
      @events = []
    end

    def add_event(event)
      @events << event
      @events.sort_by!(&:game_time)
    end

    def to_hash
      return {} # FIXME
    end

    def self.from_hash(hash)
      new # FIXME
    end

    def distance_between(start_time, stop_time)
      speed = @events.first.speed  # FIXME support changing speed after initial
      return speed * (stop_time - start_time).hours_f
    end

    def location(at_time)
      loc = Coord.new(0,0)

      initial   = @events.first
      course    = initial.course
      last_time = initial.game_time
      return if at_time < last_time
      turn_dir  = nil

      done = false
      @events.each_with_index do |event, index|
        next if index == 0 # initial event

        end_time = event.game_time
        if end_time > at_time
          end_time = at_time
          done = true
        end

        if event.begin_turn?
          loc = loc.travel(course, distance_between(last_time, end_time))
          turn_dir = event.turn_direction
          last_time = event.game_time
        elsif event.respond_to?(:new_course)
          loc = loc.travel_curved(turn_dir, course, event.new_course, distance_between(last_time, end_time))
          last_time = event.game_time
        end

        break if done
      end

      loc = loc.travel(course, distance_between(last_time, at_time)) unless done
      return loc
    end
  end
end
