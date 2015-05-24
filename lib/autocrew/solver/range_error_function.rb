require 'autocrew/solver/error_function_base'
require 'autocrew/vector'
require 'autocrew/coord'

module Autocrew::Solver
  class RangeErrorFunction < ErrorFunctionBase
    include Autocrew

    def arity
      return 5
    end

    def evaluate(pos_x, pos_y, nvel_x, nvel_y, speed)
      super(Coord.new(pos_x, pos_y), Vector.create(nvel_x, nvel_y) * speed)
    end

    def evaluate_gradient(pos_x, pos_y, nvel_x, nvel_y, speed)
      unit_start = Coord.new(pos_x, pos_y)
      time_offset = @unit.origin_time
      normal_velocity = Vector.create(nvel_x, nvel_y)
      velocity = normal_velocity * speed

      x_deriv = y_deriv = vx_deriv = vy_deriv = speed_deriv = 0.0

      @unit.observations.each_with_index do |observation, index|
        time = (observation.game_time - time_offset).hours_f
        time_velocity = velocity * time
        unit_point = unit_start + time_velocity

        observer_point = observation.observer.location(observation.game_time)
        bearing_vector = observation.bearing_vector
        obs_vector = unit_point - observer_point

        #puts
        #puts "#{index} gradient:"
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
          x_deriv     += bearing_vector.y * error
          y_deriv     -= bearing_vector.x * error
          vx_deriv    += bearing_vector.y*speed*time * error
          vy_deriv    -= bearing_vector.x*speed*time * error
          speed_deriv += (bearing_vector.y*normal_velocity.x*time - bearing_vector.x*normal_velocity.y*time) * error;
        else # otherwise, the target position is on the wrong side of the observer...
          #puts "  opposite side"
          x_deriv     += obs_vector.x
          y_deriv     += obs_vector.y
          vx_deriv    += speed * time * obs_vector.x
          vy_deriv    += speed * time * obs_vector.y
          speed_deriv += normal_velocity.x*time*obs_vector.x + normal_velocity.y*time*obs_vector.y
        end
      end

      return [
        2*x_deriv,
        2*y_deriv,
        2*vx_deriv,
        2*vy_deriv,
        2*speed_deriv
      ]
    end
  end
end
