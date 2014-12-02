require_relative 'basic_intervals'
require_relative 'error'

module IntervalNotation
  class IntervalSet
    attr_reader :intervals

    def initialize(intervals)
      @intervals = intervals
    end

    def to_s
      intervals.empty? ? 'Empty' : intervals.map(&:to_s).join('U')
    end

    def inspect; to_s; end

    def include_position?(value)
      interval = @intervals.bsearch{|interv| interv.to >= value }
      interval && interval.include_position?(value)
    end

    BoundaryPoint = Struct.new(:value, :included, :opening, :interval_index, :singular_point)

    private def interval_boundaries(interval, interval_index)
      if interval.is_a?(Point)
        BoundaryPoint.new(interval.from, true, nil, interval_index, true)
      else
        [ BoundaryPoint.new(interval.from, interval.include_from?, true, interval_index, false),
          BoundaryPoint.new(interval.to, interval.include_to?, false, interval_index, false) ]
      end
    end

    def eql?(other); other.class.equal?(self.class) && intervals == other.intervals; end
    def ==(other); other.is_a?(IntervalSet) && intervals == other.intervals; end

    # accepts a necessary inclusion_checker block.
    # It accepts an array of two boolean elements(inclusion state of both interval's segments) and returns an inclusion state of a result
    def combine(other)
      points_1 = intervals.flat_map{|interval| interval_boundaries(interval, 0) }
      points_2 = other.intervals.flat_map{|interval| interval_boundaries(interval, 1) }

      points = (points_1 + points_2).sort_by(&:value)

      intervals = []

      inside = [false, false]
      now_inside = yield inside
      incl_from = nil
      from = nil

      points.chunk(&:value).each do |point_value, points_on_place|
        prev_inside = now_inside
        included = inside.dup # if no point of given interval-set present at a place, then this interval either covers (and thus includes a point) or not
        points_on_place.each do |point|
          # two points of the same interval-set may yield only identical not-included state (i.e. false)
          included[point.interval_index] = point.included
        end

        points_on_place.reject(&:singular_point).each do |point|
          inside[point.interval_index] = !inside[point.interval_index]
        end
        now_inside = yield inside

        if !prev_inside && !now_inside
          intervals << Point.new(point_value)  if yield included
        elsif !prev_inside && now_inside
          from = point_value
          incl_from = yield included
        elsif prev_inside && !now_inside
          to = point_value
          incl_to = yield included
          intervals << interval_by_boundary_inclusion(incl_from, from, incl_to, to)
          from = nil # easier to find an error (but not necessary code)
          incl_from = nil # ditto
        else
          unless yield included
            intervals << interval_by_boundary_inclusion(incl_from, from, false, point_value)
            incl_from = false
            from = point_value
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
      combine(other, &:all?)
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
  end

  private_constant :IntervalSet
end
