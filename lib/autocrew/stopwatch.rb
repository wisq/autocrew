require 'autocrew/game_time'

class Autocrew::Stopwatch
  def initialize(game_time, real_time = Time.now)
    @game_time = game_time
    @real_time = real_time
  end

  def now
    offset = Time.now - @real_time
    @game_time + offset
  end
end
