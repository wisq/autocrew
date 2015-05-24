require 'adam_math'

module AdamMath
  module MathHelpers
    def self.with_sign(value, sign)
      (sign < 0) ^ (value < 0) ? -value : value
    end

    def self.get_magnitude(vector)
      return Math.sqrt(sum_squared_vector(vector))
    end

    def self.sum_squared_vector(vector)
      return vector.inject(0) do |sum, value|
        sum += value*value
      end
    end

    def self.negate_vector(vector)
      return vector.map { |v| -v }
    end

    def self.scale_vector(vector, scale)
      return vector.map { |v| v * scale }
    end

    def self.dot_product(a, b)
      return a.each_index.inject(0) do |sum, i|
        sum += a[i]*b[i]
      end
    end

    def self.subtract_vectors(lhs, rhs)
      return lhs.each_index.map do |i|
        lhs[i] - rhs[i]
      end
    end
  end
end
