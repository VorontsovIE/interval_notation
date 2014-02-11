# List of non-intersecting SemiIntervals.
# All empty intervals are rejected during set construction
# Intervals're stored in a sorted list (it's possible because they don't intersect each other)
# Doesn't automatically unite adjacent SemiIntervals(but you can make it manually). Ignores duplicates of regions
# Structure is immutable
module IntervalAlgebra
  class SemiIntervalSet
    attr_reader :interval_list

    def initialize(interval_list)
      @interval_list = interval_list
    rescue
      raise 'Intervals cannot be ordered without intersections'
    end

    # gets list of semiintervals, seminterval sets and arrays of semiinterals and their sets
    # returns union of them
    def self.new(*arglist)
      interval_list = arglist.flatten.map(&:interval_list).flatten.reject(&:empty?).uniq
      interval_list = unite_adjacent(interval_list.sort)
      case interval_list.size
      when 0
        EmptySemiInterval.new # returns EmptySemiInterval instead of empty SemiIntervalSet
      when 1
        interval_list.first # returns SemiInterval (instead of SemiIntervalSet containing the only SemiInterval)
      else
        super(interval_list)
      end
    end

    def self.unite_adjacent(interval_list)
      interval_list.each_with_object([]) do |interval, list|
        if list.empty?
          list.push(interval)
        elsif list.last.region_adjacent?(interval)
          list.push( list.pop.union(interval) )
        else
          list.push(interval)
        end
      end
    end

    def union(other)
      if other.contigious?
        intervals_intersecting_other_united = interval_list.select{|interval| interval.intersect?(other) }.inject(other){|result,interval| result.union(interval) }
        SemiIntervalSet.new( interval_list.select{|interval| !interval.intersect?(other)}, intervals_intersecting_other_united )
      else
        other.interval_list.inject(self){|result, interval| result.union(interval) }
      end
    end
    def intersection(other)
      SemiIntervalSet.new( interval_list.map{|interval| other.intersection(interval)} )
    end
    def subtract(other)
      if other.contigious?
        SemiIntervalSet.new( interval_list.map{|interval| interval.subtract(other) } )
      else
        other.interval_list.inject(self){|result, interval| result.subtract(interval) }
      end
    end
    def empty?; false; end
    def contigious?; false; end

    def intersect?(other)
      interval_list.any?{|interval| other.intersect?(interval)}
    end

    def contain?(other)
      if other.contigious?
        interval_list.any?{|interval| interval.contain?(other) }
      else
        other.interval_list.all?{|other_interval| self.contain?(other_interval) }
      end
    end
    def inside?(other)
      interval_list.all?{|interval| interval.inside?(other) }
    end
    def from_left?(other)
      self.rightmost_position <= other.leftmost_position
    end
    def from_right?(other)
      other.rightmost_position <= self.leftmost_position
    end

    def ==(other)
      !other.contigious? && interval_list == other.interval_list
    end

    def eql?(other); self == other; end
    def hash
      interval_list.hash
    end

    def to_s
      interval_list.map(&:to_s).join('U')
    end
    def inspect; to_s; end

    def covering_interval; SemiInterval.new(interval_list.first.pos_start, interval_list.last.pos_end); end

    def leftmost_position; interval_list.first.pos_start; end
    def rightmost_position; interval_list.last.pos_end; end

    def complement
      SemiInterval.new(-Float::INFINITY, Float::INFINITY) - self
    end

    def region_adjacent?(other)
      raise UnsupportedType, 'Unsupported type of receiver'
    end

    def include_position?(pos)
      interval_list.any?{|interval| interval.include_position?(pos)}
    end

    def |(other); union(other); end
    def &(other); intersection(other); end
    def -(other); subtract(other); end
    def ~; complement; end
  end
end
