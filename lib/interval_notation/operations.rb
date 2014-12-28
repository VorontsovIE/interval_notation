require_relative 'interval_set'
require_relative 'basic_intervals'
require_relative 'combiners'

module IntervalNotation
  module Operations
    # Union of multiple intervals.
    def union(intervals)
      UnionCombiner.new(intervals.size).combine(intervals)
    end

    # Intersection of multiple intervals
    def intersection(intervals)
      IntersectCombiner.new(intervals.size).combine(intervals)
    end

    module_function :union, :intersection
  end
end
