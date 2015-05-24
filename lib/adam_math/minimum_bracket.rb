require 'adam_math'

module AdamMath
  class MinimumBracket
    attr_reader :high1, :low, :high2

    def initialize(high1, low, high2)
      @high1 = high1
      @low   = low
      @high2 = high2
    end
  end
end
