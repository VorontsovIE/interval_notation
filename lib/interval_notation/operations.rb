require_relative 'interval_set'
require_relative 'basic_intervals'
require_relative 'combiners'

module IntervalNotation
  module Operations
    def update_inside!(points_on_place, inside)
      points_on_place.each do |point|
        inside[point.interval_index] ^= point.interval_boundary # doesn't change on singular points
      end
    end

    def update_included!(points_on_place, included)
      points_on_place.each do |point|
        # two points of the same interval-set may yield only identical not-included state (i.e. false)
        included[point.interval_index] = point.included
      end
    end

    # accepts a necessary inclusion_checker block.
    # It accepts an array of two boolean elements(inclusion state of both interval's segments) and returns an inclusion state of a result
    def combine(interval_sets, combiner)
      points = interval_sets.each_with_index.flat_map{|interval_set, interval_set_index|
        interval_set.intervals.flat_map{|interval|
          interval.interval_boundaries(interval_set_index)
        }
      }.sort_by(&:value)

      intervals = []

      now_inside = combiner.state
      # inside = Array.new(interval_sets.size, false)
      # now_inside = yield inside
      # num_inside = now_inside.count{|el| el}
      incl_from = nil
      from = nil

      points.chunk(&:value).each do |point_value, points_on_place|
        prev_inside = now_inside
        # included = inside.dup # if no point of given interval-set present at a place, then this interval either covers (and thus includes a point) or not
        # update_included!(points_on_place, included)
        # update_inside!(points_on_place, inside)
        combiner.pass(points_on_place)
        now_inside = combiner.state

        if prev_inside
          if now_inside
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
          if now_inside
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
