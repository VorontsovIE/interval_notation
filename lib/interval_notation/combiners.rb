require 'set'

module IntervalNotation
  # Combiner is an internal helper class for combining interval sets using sweep line.
  # It starts moving from -∞ to +∞ and keep which intervals are crossed by sweep line.
  # Class helps to effectively recalculate number of crossed intervals without rechecking 
  # all intervals each time, and dramatically reduces speed of operations on large number of intervals
  class Combiner
    attr_reader :num_interval_sets
    def initialize(num_interval_sets)
      @num_interval_sets = num_interval_sets
      @inside = Array.new(num_interval_sets, false)
      @num_intervals_inside = 0 # number of intervals, we are inside (for efficiency)
    end

    # when sweep line pass several interval boundaries, it should get all those points at once
    # and update status of crossing sweep line
    def pass(points_on_place)
      num_spanning_intervals = @num_intervals_inside
      num_covering_boundaries = 0

      points_on_place.each do |point|
        num_covering_boundaries += 1  if point.included

        if point.interval_boundary
          num_spanning_intervals -= 1  if point.closing
          @num_intervals_inside += (@inside[point.interval_index] ? -1 : 1)
          @inside[point.interval_index] ^= true
        end
      end
      @num_interval_sets_covering_last_point = num_spanning_intervals + num_covering_boundaries
    end
  end

  class UnionCombiner < Combiner
    # checks whether current section should be included
    def state
      @num_intervals_inside > 0
    end

    # checks whether last passed point should be included
    def include_last_point
      @num_interval_sets_covering_last_point > 0
    end
  end

  class IntersectCombiner < Combiner
    # checks whether current section should be included
    def state
      @num_intervals_inside == num_interval_sets
    end

    # checks whether last passed point should be included
    def include_last_point
      @num_interval_sets_covering_last_point == num_interval_sets
    end
  end

  class SubtractCombiner
    # checks whether last passed point should be included
    attr_reader :include_last_point

    def initialize
      @include_last_point = nil
      @inside = [false, false]
    end

    # checks whether current section should be included
    def state
      @inside[0] && ! @inside[1]
    end

    # when sweep line pass several interval boundaries, it should get all those points at once
    # and update status of crossing sweep line
    def pass(points_on_place)
      included = @inside.dup
      points_on_place.each do |point|
        @inside[point.interval_index] ^= point.interval_boundary # doesn't change on singular points
        included[point.interval_index] = point.included
      end
      @include_last_point = included[0] && !included[1]
    end
  end

  class SymmetricDifferenceCombiner
    # checks whether last passed point should be included
    attr_reader :include_last_point

    def initialize
      @include_last_point = nil
      @inside = [false, false]
    end

    # checks whether current section should be included
    def state
      @inside[0] ^ @inside[1]
    end

    # when sweep line pass several interval boundaries, it should get all those points at once
    # and update status of crossing sweep line
    def pass(points_on_place)
      included = @inside.dup
      points_on_place.each do |point|
        @inside[point.interval_index] ^= point.interval_boundary # doesn't change on singular points
        included[point.interval_index] = point.included
      end
      @include_last_point = included[0] ^ included[1]
    end
  end
end