require_relative 'basic_intervals'
require_relative 'error'

class IntervalTree
  module Helpers
    def self.consequent_intervals_not_overlap?(interval, next_interval)
      (interval.to < next_interval.from) ||
      (interval.to == next_interval.from) && (!interval.include_to? || !next_interval.include_from?)
    end

    def self.consequent_intervals_adjacent?(interval, next_interval)
      (interval.to == next_interval.from) && (interval.include_to? ^ next_interval.include_from?)
    end

    def self.sorted_intervals_not_overlap?(intervals)
      intervals.each_cons(2).all? do |interval, next_interval|
        consequent_intervals_not_overlap?(interval, next_interval)
      end
    end

    def self.glue_adjacent(interval_list)
      return []  if interval_list.empty?
      result = [interval_list.first]
      interval_list.drop(1).each do |next_interval|
        last_interval = result.last
        if consequent_intervals_adjacent?(last_interval, next_interval)
          interval_union = Interval.new_by_boundary_inclusion(last_interval.include_from?, last_interval.from,
                                                next_interval.include_to?, next_interval.to)
          result.pop
          result.push interval_union
        else
          result << next_interval
        end
      end
      result
    end
  end


  attr_reader :intervals

  def initialize(intervals)
    intervals = intervals.sort_by(&:from)
    raise Error, "Intervals shouldn't overlap"  unless Helpers.sorted_intervals_not_overlap?(intervals)
    @intervals = Helpers.glue_adjacent(intervals)
  end

  def to_s
    intervals.empty? ? 'Empty' : intervals.map(&:to_s).join('U')
  end

  def inspect; to_s; end

  def include_position?(value)
    interval = @intervals.bsearch{|interv| interv.to >= value }
    interval.include_position?(value)
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

  private def update_inside!(inside, points_on_place)
    points_on_place.reject(&:singular_point).each do |point|
      inside[point.interval_index] = !inside[point.interval_index]
    end
  end
  
  def eql?(other); other.class.equal?(self.class) && intervals == other.intervals; end
  def ==(other); other.is_a?(IntervalTree) && intervals == other.intervals; end

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

      update_inside!(inside, points_on_place)
      now_inside = yield inside

      if !prev_inside && !now_inside
        intervals << Point.new(point_value)  if yield included
      elsif !prev_inside && now_inside
        from = point_value
        incl_from = yield included
      elsif prev_inside && !now_inside
        to = point_value
        incl_to = yield included
        intervals << Interval.new_by_boundary_inclusion(incl_from, from, incl_to, to)
        from = nil # easier to find an error (but not necessary code)
        incl_from = nil # ditto
      else
        unless yield included
          intervals << Interval.new_by_boundary_inclusion(incl_from, from, false, point_value)
          incl_from = false
          from = point_value
        end
      end
    end
    IntervalTree.new(intervals)
  end

  def union(other)
    combine(other, &:any?)
  end

  def intersect(other)
    combine(other, &:all?)
  end

  def subtract(other)
    combine(other) do |included|
      included[0] && !included[1]
    end
  end
end
