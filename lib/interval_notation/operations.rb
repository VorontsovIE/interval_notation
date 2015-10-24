require_relative 'interval_set'
require_relative 'basic_intervals'
require_relative 'sweep_line'

module IntervalNotation
  module Operations
    # Union of multiple intervals.
    def union(intervals)
      SweepLine.make_interval_set(intervals, SweepLine::TraceState::Union.initial_state(intervals.size))
    end

    # Intersection of multiple intervals
    def intersection(intervals)
      SweepLine.make_interval_set(intervals, SweepLine::TraceState::Intersection.initial_state(intervals.size))
    end

    module_function :union, :intersection
  end
end
