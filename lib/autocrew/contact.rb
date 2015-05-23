require 'autocrew'

module Autocrew
  class Contact
    attr_reader :observations

    class Observation
      attr_reader :bearing

      def initialize(bearing)
        @bearing = bearing
      end
    end

    def initialize
      @observations = []
    end

    def solve
    end
  end
end
