require 'autocrew/solver'

module Autocrew::Solver
  class PenaltyFunction
    attr_reader :last_penalty

    def initialize(minimizer, penalty_factor)
      @minimizer = minimizer
      @penalty_factor = penalty_factor
    end

    def arity
      @minimizer.arity
    end

    def constraint_enforcement
      @minimizer.constraint_enforcement
    end

    def barrier_method?
      constraint_enforcement.barrier_method?
    end

    def arity_check(xs)
      raise ArgumentError.new("wrong number of arguments (#{xs.count} for #{arity})") unless xs.count == arity
    end

    def adjust_penalty_factor(change_factor)
      @penalty_factor = constraint_enforcement.new_penalty_factor(@penalty_factor, change_factor)
    end

    def penalty_value(penalty)
      constraint_enforcement.penalty_value(penalty)
    end

    def penalty_gradient(penalty)
      constraint_enforcement.penalty_gradient(penalty)
    end

    def evaluate(*xs)
      arity_check(xs)
      total_penalty = 0

      catch :done do
        # compute the penalty for out-of-bound parameters
        if @minimizer.bounds.any?
          if barrier_method?
            # barrier methods apply penalties everywhere
            xs.each_with_index do |x, i|
              next unless bound = @minimizer.bounds[i]
              total_penalty += penalty_value(bound.min - x) unless bound.min.infinite?
              total_penalty += penalty_value(x - bound.max) unless bound.max.infinite?
            end

            throw :done if total_penalty.nan?  # quit early if a barrier constraint is violated
          else
            # penalty methods have penalties only when constraints are violated
            xs.each_with_index do |x, i|
              next unless bound = @minimizer.bounds[i]
              penalty = nil
              if x < bound.min
                penalty = bound.min - x
              elsif x > bound.max
                penalty = x - bound.max
              end
              total_penalty += penalty_value(penalty) if penalty
            end
          end
        end

        @minimizer.constraints.each do |constraint|
          penalty = constraint.evaluate(*xs)
          if penalty > 0
            total_penalty += penalty_value(penalty)
            throw :done if total_penalty.nan?  # quit early if a barrier constraint is violated
          end
        end

        total_penalty *= @penalty_factor
      end

      @last_penalty = total_penalty
      return Float::NAN if total_penalty.nan?
      return @minimizer.function.evaluate(*xs) + total_penalty
    end

    def evaluate_gradient(*xs)
      arity_check(xs)
      output = @minimizer.function.evaluate_gradient(*xs)

      # compute the penalty for out-of-bound parameters
      if @minimizer.bounds.any?
        if barrier_method?
          # barrier methods apply penalties everywhere
          xs.each_with_index do |x, i|
            next unless bound = @minimizer.bounds[i]

            output[i] -= @penalty_factor * penalty_gradient(bound.min - x) unless bound.min.infinite?
            output[i] += @penalty_factor * penalty_gradient(x - bound.max) unless bound.max.infinite?
          end
        else
          # penalty methods have penalties only when constraints are violated
          xs.each_with_index do |x, i|
            next unless bound = @minimizer.bounds[i]

            if x < bound.min
              output[i] -= @penalty_factor * penalty_gradient(bound.min - x)
            elsif x > bound.max
              output[i] += @penalty_factor * penalty_gradient(x - bound.max)
            end
          end
        end
      end

      @minimizer.constraints.each do |constraint|
        penalty = constraint.evaluate(*xs)
        if penalty > 0
          penalty = @penalty_factor * penalty_gradient(penalty)
          constraint.evaluate_gradient(*xs).each_with_index do |x, i|
            output[i] += penalty * x
          end
        end
      end

      return output
    end
  end
end
