require_relative 'multiple_state'

module IntervalNotation
  module SweepLine
    module TraceState

      # Class allows to observe whether sweep line is inside of first and outside of second interval set
      class Subtract < MultipleState
        def self.initial_state
          self.new([false, false])
        end

        def state_convolution
          inclusion_state[0] && !inclusion_state[1]
        end
      end

    end
  end
end
