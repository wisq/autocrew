require 'adam_math'

module AdamMath
  class RootBracket
    attr_reader :min, :max

    def initialize(min, max)
      @min = min.to_f
      @max = max.to_f
    end

    def validate
      raise "minimum #{@min} is higher than maximum #{@max}" if @min > @max
    end

    def swap
      self.class.new(@max, @min)
    end

    def mutable
      MutableRootBracket.new(@min, @max)
    end
  end

  class MutableRootBracket < RootBracket
    attr_writer :min, :max

    def mutable
      self
    end

    def swap
      @min, @max = @max, @min
      self
    end
  end
end
