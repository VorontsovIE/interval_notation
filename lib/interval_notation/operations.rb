require_relative 'interval_set'
require_relative 'basic_intervals'
require_relative 'combiners'

module IntervalNotation
  module Operations
    # Internal method which combines intervals according to an algorithm given by a combiner.
    # Combiner tells whether current section or point should be included to a new interval.
    def combine(interval_sets, combiner)
      points = interval_sets.each_with_index.flat_map{|interval_set, interval_set_index|
        interval_set.intervals.flat_map{|interval|
          interval.interval_boundaries(interval_set_index)
        }
      }.sort_by(&:value)

      intervals = []

      incl_from = nil
      from = nil

      points.chunk(&:value).each do |point_value, points_on_place|
        combiner.pass(points_on_place)

        if combiner.previous_state
          if combiner.state
            unless combiner.include_last_point
              intervals << interval_by_boundary_inclusion(incl_from, from, false, point_value)
              incl_from = false
              from = point_value
            end
          else
            to = point_value
            incl_to = combiner.include_last_point
            intervals << interval_by_boundary_inclusion(incl_from, from, incl_to, to)
            from = nil # easier to find an error (but not necessary code)
            incl_from = nil # ditto
          end
        else
          if combiner.state
            from = point_value
            incl_from = combiner.include_last_point
          else
            intervals << IntervalNotation::Point.new(point_value)  if combiner.include_last_point
          end
        end
      end
      IntervalNotation::IntervalSet.new_unsafe(intervals)
    end

    def union(intervals)
      combine(intervals, UnionCombiner.new(intervals.size))
    end

    def intersection(intervals)
      combine(intervals, IntersectCombiner.new(intervals.size))
    end

    def interval_by_boundary_inclusion(include_from, from, include_to, to)
      if include_from
        if include_to
          if from != to
            IntervalNotation::ClosedClosedInterval.new(from, to)
          else
            IntervalNotation::Point.new(from)
          end
        else
          IntervalNotation::ClosedOpenInterval.new(from, to)
        end
      else
        if include_to
          IntervalNotation::OpenClosedInterval.new(from, to)
        else
          IntervalNotation::OpenOpenInterval.new(from, to)
        end
      end
    end
  end
end
