module IntervalNotation
  module SweepLine
    module TraceState

      # Class allows to observe whether sweep line is inside of interval sets intersection or outside
      Intersection = Struct.new(:num_uncovered) do
        def self.initial_state(num_interval_sets)
          self.new(num_interval_sets)
        end

        # map state before point into state at point
        def state_at_point(points_on_place)
          new_state = num_uncovered
          points_on_place.each{|point|
            if point.singular_point?
              new_state -= 1
            else
              if point.closing && !point.included
                new_state += 1
              elsif point.opening && point.included
                new_state -= 1
              end
            end
          }
          self.class.new(new_state)
        end

        # map state at point into state after point
        def state_after_point(points_on_place)
          new_state = num_uncovered
          points_on_place.reject(&:singular_point?).each{|point|
            new_state += point.opening ? -1 : +1
          }
          
          self.class.new(new_state)
        end

        def state_convolution
          num_uncovered == 0
        end
      end

      # # More generic but less efficient version of Intersection state
      # class IntersectionMultiState < MultipleState
      #   def self.initial_state(num_interval_sets)
      #     self.new( Array.new(num_interval_sets, false) )
      #   end

      #   def state_convolution
      #     inclusion_state.all?
      #   end
      # end

    end
  end
end
