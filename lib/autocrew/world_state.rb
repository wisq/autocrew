require 'tempfile'
require 'glomp'
require 'autocrew'

module Autocrew
  class WorldState
    include Glomp::Glompable

    attr_accessor :ownship, :contacts, :stopwatch, :focus

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

    def save(name)
      save_dir = self.class.save_directory
      Dir.mkdir(save_dir) unless Dir.exist?(save_dir)

      Tempfile.open([name, ".json"], save_dir) do |fh|
        fh.puts Glomp.glomp(self)
        fh.close
        File.rename(fh.path, File.join(save_dir, "#{name}.json"))
      end
    end

    def self.load(name)
      json = File.read(File.join(save_directory, "#{name}.json"))
      return Glomp.unglomp(json)
    end

    def self.save_directory
      ENV['AUTOCREW_HOME'] || File.join(ENV['HOME'], '.autocrew')
    end

    def focused_contact
      return @contacts[@focus]
    end

    def display_points
      return [] unless @stopwatch && @ownship

      now = @stopwatch.now
      hour_ago = now - GameTime.parse("01:00")
      times = [hour_ago, now]

      points = times.map { |time| @ownship.location(time) }
      if contact = focused_contact
        points += times.map { |time| contact.location(time) }
      end

      return points
    end
  end
end
