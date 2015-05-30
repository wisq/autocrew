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
      end

      raise ExtraWordsError unless @words.empty?
      return command
    end

    def parse_contact(id)
      word = @words.shift
      if word == "bearing"
        return ContactBearing.new(id, @time, @words.shift)
      end
    end

    class ContactBearing
      def initialize(id, time, bearing)
        @id = id
        @time = time
        raise ValueError unless bearing =~ /^[0-9]+(?:\.[0-9]+)?$/
        @bearing = bearing.to_f
      end

      def execute(state)
        contact = state.contacts[@id] || Contact.new
        contact.add_observation(state.ownship, @time, @bearing)
        state.contacts[@id] ||= contact
      end
    end
  end
end
