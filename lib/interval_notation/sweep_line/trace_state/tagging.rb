require 'set'

module IntervalNotation
  module SweepLine
    module TraceState

      # Tagging is an abstract state class which stores an overlay markup of several tagged interval-sets.
      # Look at SingleTagging and MultiTagging which implement different convolution strategies (see below). 
      #
      # Each interval set can be marked with the only tag but for an overlay each individual point
      # can be marked with zero to many tags.
      # Tag name is taken from boundary point's interval index.
      # Tag names needn't be unique.
      #
      # When a point is overlapped by several tags with the same name, there are two strategies:
      # * SingleTagging takes into account only the fact, that the point/interval was tagged
      # * MultiTagging count the number of times each tag was assigned to a point/interval
      #
      Tagging = Struct.new(:tag_count) do
        def self.initial_state
          self.new(Hash.new(0))
        end

        # map state before point into state at point
        def state_at_point(points_on_place)
          new_state = tag_count.dup
          points_on_place.each{|point|
            if point.singular_point?
              new_state[point.interval_index] += 1
            else
              if point.closing && !point.included
                new_state[point.interval_index] -= 1
              elsif point.opening && point.included
                new_state[point.interval_index] += 1
              end
            end
          }
          new_state.reject!{|tag, count| count.zero?}
          self.class.new(new_state)
        end

        # map state before point (not at point!) into state after point
        def state_after_point(points_on_place)
          new_state = tag_count.dup
          points_on_place.reject(&:singular_point?).each{|point|
            new_state[point.interval_index] += point.opening ? 1 : -1
          }
          new_state.reject!{|tag, count| count.zero?}
          self.class.new(new_state)
        end

        # Convolve state inner state into state result
        def state_convolution
          raise NotImplementedError, 'Tagging is an abstract state class. Use SingleTagging or MultiTagging instead'
        end
      end

      class SingleTagging < Tagging
        def state_convolution; tag_count.keys.to_set; end
        def to_s; "{#{tag_count.keys.join(', ')}}"; end
        def inspect; to_s; end
      end

      class MultiTagging < Tagging
        def state_convolution; tag_count; end
        def to_s; tag_count.to_s; end
        def inspect; to_s; end
      end

    end
  end
end
