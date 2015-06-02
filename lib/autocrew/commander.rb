require 'autocrew/game_time'
require 'autocrew/ownship'
require 'autocrew/stopwatch'
require 'autocrew/event'

module Autocrew
  class Commander
    class ExtraWordsError < StandardError; end
    class UnknownCommandError < StandardError; end
    class ValueError < StandardError; end

    attr_reader :params

    def initialize(parent = nil, params = {})
      if parent
        @params = parent.params.merge(params)
      else
        @params = params
      end
    end

    def apply(params)
      self.class.new(self, params)
    end

    def game_time
      return params[:game_time]
    end

    def commands
      return {
        'at' => AtCommand,
        'sync' => SyncCommand,
        'restart' => RestartCommand,
        'ownship' => OwnshipCommand,
        :match => {
          /^[a-z][0-9]+$/ => ContactCommander,
        }
      }
    end

    def parse(text, command_list = commands)
      command, rest = text.split(/\s+/, 2)

      if cls = command_list[command]
        return cls.parse(self, command, rest)
      end

      command_list[:match].each do |regex, cls|
        if command =~ regex
          return cls.parse(self, command, rest)
        end
      end

      raise UnknownCommandError
    end

    class AtCommand
      def self.parse(cmdr, _, text)
        time_str, rest = text.split(/\s+/, 2)
        time = GameTime.parse(time_str)
        return cmdr.apply(game_time: time).parse(rest)
      end
    end

    class ContactCommander < Commander
      def commands
        return {
          'bearing' => ContactBearingCommand,
        }
      end

      def contact_id
        return params[:contact_id]
      end

      def self.parse(cmdr, id, text)
        return new(cmdr, contact_id: id).parse(text)
      end
    end

    class ContactBearingCommand
      def self.parse(cmdr, _, bearing)
        raise ValueError unless bearing =~ /^[0-9]+(?:\.[0-9]+)?$/
        return new(cmdr.contact_id, cmdr.game_time, bearing.to_f)
      end

      def initialize(id, time, bearing)
        @id = id
        @time = time
        @bearing = bearing
      end

      def execute(state)
        contact = state.contacts[@id] || Contact.new
        contact.add_observation(state.ownship, @time || state.stopwatch.now, @bearing)
        state.contacts[@id] ||= contact
      end
    end

    class OwnshipCommand
      def self.parse(cmdr, _, text)
        words = text.split(/\s+/)

        if text =~ /^(?:course|bearing) (\S+) speed (\S+)$/
          course = $1
          speed  = $2
        else
          raise "Usage: ownship course ## speed ##"
        end

        raise ValueError unless course =~ /^[0-9]+(?:\.[0-9]+)?$/
        raise ValueError unless speed  =~ /^[0-9]+(?:\.[0-9]+)?$/

        return new(cmdr.game_time, course.to_f, speed.to_f)
      end

      def initialize(time, course, speed)
        @time   = time
        @course = course
        @speed  = speed
      end

      def execute(state)
        ownship = Ownship.new
        ownship.add_event(Event::Initial.new(@time, @course, @speed))
        state.ownship = ownship
      end
    end

    class SyncCommand
      def self.parse(_, _, time_str)
        return new(GameTime.parse(time_str))
      end

      def initialize(time)
        @time = time
      end

      def execute(state)
        state.stopwatch = Stopwatch.new(@time)
      end
    end

    class RestartCommand
      def self.parse(*_)
        return new
      end

      def execute(state)
        state.save('restart')
        ENV['AUTOCREW_LOAD'] = 'restart'
        exec($0)
      end
    end
  end
end
