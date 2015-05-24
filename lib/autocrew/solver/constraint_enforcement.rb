require 'autocrew/solver'

module Autocrew::Solver::ConstraintEnforcement
  class Barrier
    def barrier_method?
      true
    end

    def new_penalty_factor(factor, change_factor)
      return factor / change_factor
    end
  end

  class NonBarrier
    def barrier_method?
      false
    end

    def new_penalty_factor(factor, change_factor)
      return factor * change_factor
    end
  end

  class LinearPenalty < NonBarrier
    def penalty_value(penalty)
      return penalty
    end

    def penalty_gradient(penalty)
      return 1
    end
  end

  class QuadraticPenalty < NonBarrier
    def penalty_value(penalty)
      return penalty*penalty
    end

    def penalty_gradient(penalty)
      return 2 * penalty
    end
  end

  class InverseBarrier < Barrier
    def penalty_value(penalty)
      return Float::NAN if penalty >= 0
      return -1/penalty
    end

    def penalty_gradient(penalty)
      return Float::NAN if penalty >= 0
      return 1/(penalty*penalty)
    end
  end

  class LogBarrier < Barrier
    def penalty_value(penalty)
      return Float::NAN if penalty >= 0
      return -Math.log(-penalty)
    end

    def penalty_gradient(penalty)
      return Float::NAN if penalty >= 0
      return -1/penalty
    end
  end
end
