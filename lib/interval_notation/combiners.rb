require 'set'

module IntervalNotation
  # Combiner is an internal helper class for combining interval sets using sweep line.
  # It starts moving from -∞ to +∞ and keep which intervals are crossed by sweep line.
  # Class helps to effectively recalculate number of crossed intervals without rechecking
  # all intervals each time, and dramatically reduces speed of operations on large number of intervals.
  #
  # Usage example:
  #   UnionCombiner.new(3).combine([interval_1, interval_2, interval_3])
  class Combiner
    attr_reader :num_interval_sets
    attr_reader :previous_state

    def initialize(num_interval_sets)
      @num_interval_sets = num_interval_sets
      @inside = Array.new(num_interval_sets, false)
      @num_intervals_inside = 0 # number of intervals, we are inside (for efficiency)
    end

    # Combines intervals according on an information given by #state/#include_last_point functions
    # which tell whether current section or point should be included to a new interval.
    def combine(interval_sets)
      points = interval_sets.each_with_index.flat_map{|interval_set, interval_set_index|
        interval_set.intervals.flat_map{|interval|
          interval.interval_boundaries(interval_set_index)
        }
      }.sort_by(&:value)

      intervals = []

      incl_from = nil
      from = nil

      points.chunk(&:value).each do |point_value, points_on_place|
        pass(points_on_place)

        if previous_state
          if state
            unless include_last_point
              intervals << BasicIntervals.interval_by_boundary_inclusion(incl_from, from, false, point_value)
              incl_from = false
              from = point_value
            end
          else
            to = point_value
            incl_to = include_last_point
            intervals << BasicIntervals.interval_by_boundary_inclusion(incl_from, from, incl_to, to)
            from = nil # easier to find an error (but not necessary code)
            incl_from = nil # ditto
          end
        else
          if state
            from = point_value
            incl_from = include_last_point
          else
            intervals << BasicIntervals::Point.new(point_value)  if include_last_point
          end
        end
      end
      IntervalSet.new_unsafe(intervals)
    end

    # When sweep line pass several interval boundaries, +#pass+ should get all those points at once
    # and update status of crossing sweep line.
    # It also stores previous state, because it's actively used downstream.
    def pass(points_on_place)
      @previous_state = state
      pass_recalculation(points_on_place)
    end

    # See +#pass+ for details
    def pass_recalculation(points_on_place) # :nodoc:
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
    private :pass_recalculation
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

  class SubtractCombiner < Combiner
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

    # See +#pass+ for details
    def pass_recalculation(points_on_place) # :nodoc:
      included = @inside.dup
      points_on_place.each do |point|
        @inside[point.interval_index] ^= point.interval_boundary # doesn't change on singular points
        included[point.interval_index] = point.included
      end
      @include_last_point = included[0] && !included[1]
    end
    private :pass_recalculation
  end

  class SymmetricDifferenceCombiner < Combiner
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

    # See +#pass+ for details
    def pass_recalculation(points_on_place) # :nodoc:
      included = @inside.dup
      points_on_place.each do |point|
        @inside[point.interval_index] ^= point.interval_boundary # doesn't change on singular points
        included[point.interval_index] = point.included
      end
      @include_last_point = included[0] ^ included[1]
    end
    private :pass_recalculation
  end
end
