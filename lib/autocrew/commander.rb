require 'autocrew'

module Autocrew
  class Commander
    class ExtraWordsError < StandardError; end
    class ValueError < StandardError; end

    def initialize(text)
      @words = text.split(/\s+/)
      @time = nil
    end

    def parse
      word = @words.shift

      # Modifiers:
      if word == "at"
        @time = GameTime.parse(@words.shift)
        return parse
      end

      if word =~ /^[a-z][0-9]+$/
        command = parse_contact(word)
      elsif word == "sync"
        command = SyncCommand.new(GameTime.parse(@words.shift))
      end

      raise ExtraWordsError unless @words.empty?
      return command
    end

    def parse_contact(id)
      word = @words.shift
      if word == "bearing"
        return ContactBearingCommand.new(id, @time, @words.shift)
      end
    end

    class ContactBearingCommand
      def initialize(id, time, bearing)
        @id = id
        @time = time
        raise ValueError unless bearing =~ /^[0-9]+(?:\.[0-9]+)?$/
        @bearing = bearing.to_f
      end

      def execute(state)
        contact = state.contacts[@id] || Contact.new
        contact.add_observation(state.ownship, @time || state.stopwatch.now, @bearing)
        state.contacts[@id] ||= contact
      end
    end

    class SyncCommand
      def initialize(time)
        @time = time
      end

      def execute(state)
        state.stopwatch = Stopwatch.new(@time)
      end
    end
  end
end
