require 'autocrew/solver'

module Autocrew::Solver
  class ErrorFunctionBase
    def initialize(unit)
      @unit = unit
    end

    def derivative_count
      return 1
    end

    def evaluate(unit_start, velocity)
      sq_error = 0.0

      @unit.observations.each_with_index do |observation, index|
        time = observation.game_time.hours_f
        time_velocity = velocity * time
        unit_point = unit_start + time_velocity

        observer_point = observation.observer.location(observation.game_time)
        bearing_vector = observation.bearing_vector
        obs_vector = unit_point - observer_point

        #puts
        #puts "#{index} evaluate:"
        #puts "  time           = #{time.inspect}"
        #puts "  velocity       = #{velocity.inspect}"
        #puts "  unit_point     = #{unit_point.inspect}"
        #puts "  observer_point = #{observer_point.inspect}"
        #puts "  bearing_vector = #{bearing_vector.inspect}"
        #puts "  obs_vector     = #{obs_vector.inspect}"

        if bearing_vector.dot_product(obs_vector) >= 0  # if the target position is on the correct side of the observer...
          # then the error is the signed distance to the bearing line, which equals the dot product of the cross vector (which is
          # already normalized) and the observation vector
          error = bearing_vector.cross_vector.dot_product(obs_vector)
          #puts "  same side, error = #{error.inspect}"
          sq_error += error*error
        else  # otherwise, the target position is on the wrong side of the observer...
          #puts "  opposite side"
          sq_error += unit_point.distance_squared_to(observer_point)  # use the distance from the observer as the error
        end
      end

      return sq_error
    end
  end
end
