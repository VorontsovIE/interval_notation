require 'set'

# It starts at -INF and keep whether union of interval sets cover current place which is moved right with a sweeping line
# sweeping line takes points on its path (strictly, chunks of points with the same coordinates) and update inside-status
# to change from before passing a coordinate to after passing it.
class Combiner
  attr_reader :num_interval_sets
  def initialize(num_interval_sets)
    @num_interval_sets = num_interval_sets
    @inside = Array.new(num_interval_sets, false)
    @num_intervals_inside = 0 # number of intervals, we are inside (for efficiency)
  end

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
  def state
    @num_intervals_inside > 0
  end

  def include_last_point
    @num_interval_sets_covering_last_point > 0
  end
end

class IntersectCombiner < Combiner
  def state
    @num_intervals_inside == num_interval_sets
  end

  def include_last_point
    @num_interval_sets_covering_last_point == num_interval_sets
  end
end

class SubtractCombiner
  attr_reader :include_last_point

  def initialize(num_interval_sets)
    @include_last_point = nil
    @inside = Array.new(num_interval_sets, false)
  end

  def state
    @inside[0] && ! @inside[1]
  end

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
  attr_reader :include_last_point

  def initialize(num_interval_sets)
    @include_last_point = nil
    @inside = Array.new(num_interval_sets, false)
  end

  def state
    @inside[0] ^ @inside[1]
  end

  def pass(points_on_place)
    included = @inside.dup
    points_on_place.each do |point|
      @inside[point.interval_index] ^= point.interval_boundary # doesn't change on singular points
      included[point.interval_index] = point.included
    end
    @include_last_point = included[0] ^ included[1]
  end
end
