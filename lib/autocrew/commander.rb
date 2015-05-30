require 'autocrew'

module Autocrew
  class Commander
    class ExtraWordsError < StandardError; end
    class ValueError < StandardError; end

    def parse(state, text)
      words = text.split(/\s+/)

      time = nil
      until words.empty?
        word = words.shift

        if word == "at"
          time = GameTime.parse(words.shift)
        elsif word =~ /[a-z][0-9]+/
          return parse_contact(state, time, word, words)
        end
      end
    end

    def parse_contact(state, time, id, words)
      contact = state.contacts[id] || Contact.new

      done = false
      until words.empty? || done
        word = words.shift

        if word == "bearing"
          raise ExtraWordsError unless words.count == 1
          contact_bearing(contact, state.ownship, time, words.first)
          break
        end
      end

      state.contacts[id] ||= contact
    end

    def contact_bearing(contact, ownship, time, bearing)
      raise ValueError unless bearing =~ /^[0-9]+(?:\.[0-9]+)?$/
      contact.add_observation(ownship, time, bearing.to_f)
    end
  end
end
