module IntervalNotation
  module SweepLine
    module TraceState

      # Class allows to observe whether sweep line is inside of interval sets union or outside
      Union = Struct.new(:num_covered) do
        def self.initial_state(num_interval_sets)
          self.new(0)
        end

        # map state before point into state at point
        def state_at_point(points_on_place)
          new_state = num_covered
          points_on_place.each{|point|
            if point.singular_point?
              new_state += 1
            else
              if point.closing && !point.included
                new_state -= 1
              elsif point.opening && point.included
                new_state += 1
              end
            end
          }
          self.class.new(new_state)
        end

        # map state at point into state after point
        def state_after_point(points_on_place)
          new_state = num_covered
          points_on_place.reject(&:singular_point?).each{|point|
            new_state += point.opening ? 1 : -1
          }
          
          self.class.new(new_state)
        end

        def state_convolution
          num_covered > 0
        end
      end

      # # More generic but less efficient version of Union state
      # require_relative 'multiple_state'
      # class Union < MultipleState
      #   def self.initial_state(num_interval_sets)
      #     self.new( Array.new(num_interval_sets, false) )
      #   end

      #   def state_convolution
      #     inclusion_state.any?
      #   end
      # end

    end
  end
end
