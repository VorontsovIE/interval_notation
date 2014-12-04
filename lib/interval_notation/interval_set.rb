require_relative 'basic_intervals'
require_relative 'error'

module IntervalNotation::PrivateZone
  class IntervalSet
    attr_reader :intervals

    def initialize(intervals)
      @intervals = intervals
    end

    def to_s
      intervals.empty? ? "∅" : intervals.map(&:to_s).join('U')
    end

    def inspect; to_s; end

    def include_position?(value)
      interval = @intervals.bsearch{|interv| interv.to >= value }
      interval && interval.include_position?(value)
    end

    def eql?(other); other.class.equal?(self.class) && intervals == other.intervals; end
    def ==(other); other.is_a?(IntervalSet) && intervals == other.intervals; end

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
    def combine(other)
      points_1 = intervals.flat_map{|interval| interval.interval_boundaries(0) }
      points_2 = other.intervals.flat_map{|interval| interval.interval_boundaries(1) }

      points = (points_1 + points_2).sort_by(&:value)

      intervals = []

      inside = [false, false]
      now_inside = yield inside
      incl_from = nil
      from = nil

      points.chunk(&:value).each do |point_value, points_on_place|
        prev_inside = now_inside
        included = inside.dup # if no point of given interval-set present at a place, then this interval either covers (and thus includes a point) or not
        update_included!(points_on_place, included)
        update_inside!(points_on_place, inside)
        now_inside = yield inside

        if prev_inside
          if now_inside
            unless yield included
              intervals << interval_by_boundary_inclusion(incl_from, from, false, point_value)
              incl_from = false
              from = point_value
            end
          else
            to = point_value
            incl_to = yield included
            intervals << interval_by_boundary_inclusion(incl_from, from, incl_to, to)
            from = nil # easier to find an error (but not necessary code)
            incl_from = nil # ditto
          end
        else
          if now_inside
            from = point_value
            incl_from = yield included
          else
            intervals << Point.new(point_value)  if yield included
          end
        end
      end
      IntervalSet.new(intervals)
    end

    def union(other)
      combine(other) do |included|
        included[0] || included[1]
      end
    end

    def intersect(other)
      combine(other) do |included|
        included[0] && included[1]
      end
    end

    def subtract(other)
      combine(other) do |included|
        included[0] && !included[1]
      end
    end

    def symmetric_difference(other)
      combine(other) do |included|
        included[0] ^ included[1]
      end
    end

    def complement
      R.subtract(self)
    end

    def include?(other)
      other == (self.intersect(other))
    end

    alias :& :intersect
    alias :| :union
    alias :- :subtract
    alias :^ :symmetric_difference
    alias :~ :complement

    def interval_by_boundary_inclusion(include_from, from, include_to, to)
      if include_from
        if include_to
          if from != to
            ClosedClosedInterval.new(from, to)
          else
            Point.new(from)
          end
        else
          ClosedOpenInterval.new(from, to)
        end
      else
        if include_to
          OpenClosedInterval.new(from, to)
        else
          OpenOpenInterval.new(from, to)
        end
      end
    end

  end
end
