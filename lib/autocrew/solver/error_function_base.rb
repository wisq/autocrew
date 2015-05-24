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

      @unit.observations.each do |observation|
        unit_point = unit_start + velocity*observation.game_time.hours_f

        observer_point = observation.observer.location(observation.game_time)
        bearing_vector = observation.bearing_vector
        obs_vector = unit_point - observer_point

        if bearing_vector.dot_product(obs_vector) >= 0  # if the target position is on the correct side of the observer...
          # then the error is the signed distance to the bearing line, which equals the dot product of the cross vector (which is
          # already normalized) and the observation vector
          error = bearing_vector.cross_vector.dot_product(obs_vector)
          sq_error += error*error
        else  # otherwise, the target position is on the wrong side of the observer...
          sq_error += unit_point.distance_squared_to(observer_point)  # use the distance from the observer as the error
        end
      end

      return sq_error
    end
  end
end
