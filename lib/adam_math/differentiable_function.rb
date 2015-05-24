require 'adam_math'

module AdamMath
  class DifferentiableFunction
    attr_reader :function

    def initialize(function, derivative)
      @function = function
      @derivative = derivative
    end

    def call(x)
      @function.call(x)
    end

    # Returns the value of the function's first derivative at the given point.
    def call_derivative(x, derivs = 1)
      raise "derivs must be 1" unless derivs == 1
      @derivative.call(x)
    end

    def derivative_count
      1
    end
  end
end
