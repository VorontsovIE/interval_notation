module IntervalNotation
  module SweepLine
    module TraceState

      # MultipleState is a simple abstract class to store and manage state of intersection with sweep line of several interval sets
      # 
      # In order to use it one should define subclass with `#state_convolution` method.
      # If specific convolution can be defined in easier terms, `#state_at_point` and `#state_after_point`
      # also can be redefined in a subclass for perfomance and clarity reasons
      MultipleState = Struct.new(:inclusion_state) do
        # map state before point into state at point
        def state_at_point(points_on_place)
          new_state = inclusion_state.dup
          points_on_place.each{|point|
            new_state[point.interval_index] = point.included
          }
          self.class.new(new_state)
        end

        # map state before point (not at point!) into state after point
        def state_after_point(points_on_place)
          new_state = inclusion_state.dup

          interval_boundary_points = points_on_place.reject(&:singular_point?)
          points_by_closing = interval_boundary_points.group_by(&:closing)
          closing_points = points_by_closing.fetch(true){ [] }
          opening_points = points_by_closing.fetch(false){ [] }

          closing_points.each{|point|
            new_state[point.interval_index] = false
          }
          opening_points.each{|point|
            new_state[point.interval_index] = true
          }
          self.class.new(new_state)
        end

        # Convolve state inner state into state result
        def state_convolution
          raise NotImplementedError, '#state_convolution should be redefined in a superclass'
        end
      end

    end
  end
end
