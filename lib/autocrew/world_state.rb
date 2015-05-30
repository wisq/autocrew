require 'autocrew'

module Autocrew
  class WorldState
    include Glomp::Glompable

    attr_accessor :ownship, :contacts, :stopwatch

    def initialize
      @contacts = {}
    end

    def to_hash
      return {
        'ownship'   => @ownship,
        'contacts'  => @contacts,
        'stopwatch' => @stopwatch,
      }
    end

    def self.from_hash(hash)
      state = new
      state.ownship = hash['ownship']
      state.contacts = hash['contacts']
      state.stopwatch = hash['stopwatch']
      return state
    end
  end
end
