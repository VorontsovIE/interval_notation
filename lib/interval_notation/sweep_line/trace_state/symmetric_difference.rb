require_relative 'multiple_state'

module IntervalNotation
  module SweepLine
    module TraceState

      # Class allows to observe whether sweep line is inside of exactly one of two intervals
      class SymmetricDifference < MultipleState
        def self.initial_state
          self.new([false, false])
        end

        def state_convolution
          inclusion_state[0] ^ inclusion_state[1]
        end
      end

    end
  end
end
