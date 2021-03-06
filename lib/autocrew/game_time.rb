require 'autocrew'

module Autocrew
  class GameTime
    include Glomp::Glompable

    def self.parse(text)
      if text =~ /\A(?:(\d+)[d+]\s*)?(\d+):(\d+)(?::(\d+(?:\.\d+)?))?\z/
        from_values($1.to_i, $2.to_i, $3.to_i, $4.to_f)
      else
        raise "Can't parse game time: #{text.inspect}"
      end
    end

    def self.from_values(day, hour, minute, second)
      new(day * 86400 + hour * 3600 + minute * 60 + second)
    end

    def initialize(timestamp)
      @timestamp = timestamp
    end

    def day
      @timestamp.floor / 86400
    end

    def hour
      @timestamp.floor % 86400 / 3600
    end

    def hours_f
      @timestamp / 3600.0
    end

    def minute
      @timestamp.floor % 3600 / 60
    end

    def second
      @timestamp % 60.0
    end

    def to_f
      @timestamp
    end

    def hash
      self.class.hash + @timestamp.hash
    end

    def ==(other)
      other.to_f == self.to_f
    end
    alias eql? ==

    def +(other)
      self.class.new(@timestamp + other.to_f)
    end

    def -(other)
      self.class.new(@timestamp - other.to_f)
    end

    def <(other)
      self.to_f < other.to_f
    end

    def <=(other)
      self.to_f <= other.to_f
    end

    def >=(other)
      self.to_f >= other.to_f
    end

    def >(other)
      self.to_f > other.to_f
    end

    def <=>(other)
      self.to_f <=> other.to_f
    end

    def to_hash
      return {'timestamp': @timestamp}
    end

    def floor(step = 1.0)
      return GameTime.new(to_f - (to_f % step.to_f))
    end

    def self.from_hash(hash)
      new(hash['timestamp'])
    end
  end
end
