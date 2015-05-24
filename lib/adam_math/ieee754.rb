require 'adam_math'

module AdamMath
  class IEEE754
    # The smallest double-precision floating-point number that, when added to 1.0, produces a result not equal to 1.0.
    DOUBLE_PRECISION = 2.2204460492503131e-16
    # The square root of DOUBLE_PRECISION.
    SQRT_DOUBLE_PRECISION = 0.00000001490116119
  end
end
