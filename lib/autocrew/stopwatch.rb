require 'autocrew/game_time'

class Autocrew::Stopwatch
  include Glomp::Glompable

  attr_reader :game_time, :real_time

  def initialize(game_time, real_time = Time.now)
    @game_time = game_time
    @real_time = real_time
  end

  def now
    offset = Time.now - @real_time
    @game_time + offset
  end

  def to_hash
    return {
      'game_time' => @game_time,
      'real_time' => @real_time.to_f,
    }
  end

  def self.from_hash(hash)
    return new(hash['game_time'], Time.at(hash['real_time']))
  end
end
