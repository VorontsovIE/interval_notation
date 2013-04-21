# EmptySemiInterval -- empty region
# SemiInterval -- single contigious semi-interval
# SemiIntervalSet -- set of several(more than one) non-intersecting (but possibly adjacent) contigious semi-intervals

# pos_start and pos_end possibly can be of any class (for example GenomePosition class) but positions shpuld be compabale and pos_start should be less then pos_end
# pos_start, pos_end, adjacent? are not common

# Non-obvious: 
# 1) whether region+left_adjacent.contain?( (region+left.adjacent).unite_adjacent )
# 2) (region+left_adjacent).contigious?

# add operator ~ (interval complement)

class SemiInterval
  attr_reader :pos_start, :pos_end
  def initialize(pos_start, pos_end)
    @pos_start, @pos_end = pos_start, pos_end
  end
  
  def self.new(pos_start, pos_end)
    if pos_start < pos_end
      super
    elsif pos_start == pos_end
      EmptySemiInterval.new
    else
      raise 'Order of ends of an interval changed'
    end
  end
  
  def contigious?; true; end
  def empty?; false; end
  def length; pos_end - pos_start; end
  def include_position?(pos); (pos_start...pos_end).include?(pos); end
  
  # self is <mutual_alignment(other)> to other
  def mutual_alignment(other)
    raise "Unsupported class #{other.class}"  unless other.is_a?(SemiInterval)
    return  :undefined if other.empty?
    if pos_start == other.pos_start && pos_end == other.pos_end
      :equal
    elsif pos_start == other.pos_start && pos_end < other.pos_end
      :inside_contacted_left
    elsif pos_start == other.pos_start && pos_end > other.pos_end
      :contain_contacted_left
    elsif pos_end == other.pos_end && pos_start > other.pos_start
      :inside_contacted_right
    elsif pos_end == other.pos_end && pos_start < other.pos_start
      :contain_contacted_right
    elsif pos_start > other.pos_start && pos_end < other.pos_end
      :inside
    elsif pos_start < other.pos_start && pos_end > other.pos_end
      :contain
    elsif pos_end == other.pos_start
      :outside_left_adjacent
    elsif pos_start == other.pos_end
      :outside_right_adjacent
    elsif pos_end < other.pos_start
      :left
    elsif pos_start > other.pos_end
      :right
    elsif pos_start < other.pos_start && pos_end > other.pos_start && pos_end < other.pos_end
      :left_intersect
    elsif pos_start > other.pos_start && pos_start < other.pos_end && pos_end > other.pos_end
      :right_intersect
    else
      raise 'Mutual alignment failed. Logic error: this branch of code should never work'
    end
  end
  private :mutual_alignment

  def intersection_with_region(other)
    case mutual_alignment(other)
    when :undefined  then EmptySemiInterval.new
    when :equal  then self
    when :inside, :inside_contacted_left, :inside_contacted_right  then self
    when :contain, :contain_contacted_left, :contain_contacted_right  then other
    when :outside_left_adjacent, :outside_right_adjacent, :left, :right  then EmptySemiInterval.new
    when :left_intersect   then SemiInterval.new(other.pos_start, pos_end)
    when :right_intersect   then SemiInterval.new(pos_start, other.pos_end)
    end
  end
  private :intersection_with_region
  def intersection(other)
    case other
    when SemiInterval then intersection_with_region(other)
    when SemiIntervalSet then other.intersection(self)
    else raise 'Unsupported type'
    end
  end
  
  def union_with_region(other)
    case mutual_alignment(other)
    when :undefined  then self
    when :equal  then self
    when :inside, :inside_contacted_left, :inside_contacted_right  then other
    when :contain, :contain_contacted_left, :contain_contacted_right  then self
    when :left_intersect, :outside_left_adjacent  then SemiInterval.new(pos_start, other.pos_end)
    when :right_intersect, :outside_right_adjacent  then SemiInterval.new(other.pos_start, pos_end)
    when :left, :right   then SemiIntervalSet.new( self, other )   
    end
  end
  private :union_with_region
  def union(other)
    case other
    when SemiInterval then union_with_region(other)
    when SemiIntervalSet then other.union(self)
    else raise 'Unsupported type'
    end
  end
  
  def subtract_with_region(other)
    case mutual_alignment(other)
    when :undefined  then self
    when :equal  then EmptySemiInterval.new
    when :inside, :inside_contacted_left, :inside_contacted_right  then EmptySemiInterval.new
    when :contain  then SemiIntervalSet.new( SemiInterval.new(pos_start, other.pos_start), SemiInterval.new(other.pos_end, pos_end) )
    when :left_intersect then SemiInterval.new(pos_start, other.pos_start)
    when :right_intersect then SemiInterval.new(other.pos_end, pos_end)
    when :contain_contacted_left then SemiInterval.new(other.pos_end, pos_end)
    when :contain_contacted_right then SemiInterval.new(pos_start, other.pos_start)
    when :left, :right, :outside_left_adjacent, :outside_right_adjacent  then self
    end
  end
  private :subtract_with_region
  def subtract(other)
    case other
    when SemiInterval then subtract_with_region(other)
    when SemiIntervalSet then other.interval_list.inject(self){|result, interval| result.subtract(interval) }
    else raise 'Unsupported type'
    end
  end

  def intersect?(other)
    ! intersection(other).empty?
  end
  def contain?(other)
    case other
    when SemiInterval
      pos_start <= other.pos_start && other.pos_end <= pos_end
    when SemiIntervalSet
      other.interval_list.all?{|interval| self.contain?(interval)}
    else
      raise 'Unsupported type'
    end
  end
  def inside?(other)
    case other
    when SemiInterval
      other.pos_start <= pos_start && pos_end <= other.pos_end
    when SemiIntervalSet
      other.interval_list.any?{|interval| self.inside?(interval)}
    else
      raise 'Unsupported type'
    end
  end
  def from_left?(other)
    case other
    when SemiInterval, SemiIntervalSet
      self.rightmost_position <= other.leftmost_position
    else
      raise 'Unsupported type'
    end
  end
  def from_right?(other)
    case other
    when SemiInterval, SemiIntervalSet
      other.rightmost_position <= self.leftmost_position
    else
      raise 'Unsupported type'
    end
  end
  def adjacent?(other)
    case other
    when SemiInterval
      [:outside_left_adjacent, :outside_right_adjacent].include?  mutual_alignment(other)
    when SemiInterval
      raise 'adjacent? not supported for SemiIntervalSet'
    else
      raise 'Unsupported type'
    end
  end

  def ==(other)
    case other
    when SemiInterval
      pos_start == other.pos_start && pos_end == other.pos_end
    else
      false
    end
  end

  def <=>(other)
    case other
    when SemiInterval
      return 0 if self == other
      return -1 if self.from_left?(other)
      return 1 if self.from_right?(other)
      nil
    when SemiIntervalSet
      return -1 if other.interval_list.all?{|interval| self.from_left?(interval)}
      return 1 if other.interval_list.all?{|interval| self.from_right?(interval)}
      nil
    else
      raise 'Unsupported type'
    end
  end
  include Comparable
  alias_method :eql? , :==
  def hash
    (pos_start...pos_end).hash
  end
  
  def to_s
    "[#{pos_start};#{pos_end})"
  end
  alias_method :inspect, :to_s
  
  def interval_list; [self]; end
  def unite_adjacent; self; end
  def covering_interval; self; end
  def leftmost_position; pos_start; end
  def rightmost_position; pos_end; end
  alias_method :|, :union
  alias_method :&, :intersection
  alias_method :-, :subtract
end

class EmptySemiInterval < SemiInterval
  def self.new
    @empty_semi_interval ||= begin
      obj = allocate
      obj.send :initialize
      obj
    end
  end
  
  def initialize; end
  def empty?; true; end
  def length; 0; end
  def intersection(other); self; end
  def union(other); other; end
  def subtract(other); self; end
  def contain?(other); nil; end
  def inside?(other); nil; end
  def adjacent?(other); nil; end
  def from_left?(other); nil; end
  def from_right?(other); nil; end
  def intersect?(other); nil; end
  def ==(other); other.empty?; end
  def <=>(other); self == other ? 0 : nil; end
  def to_s; "[empty)"; end
  def covering_interval; self; end
  alias_method :|, :union
  alias_method :&, :intersection
  alias_method :-, :subtract
end

# List of non-intersecting SemiIntervals.
# All empty intervals are rejected during set construction
# Intervals're stored in a sorted list (it's possible because they don't intersect each other)
# Doesn't automatically unite adjacent SemiIntervals(but you can make it manually). Ignores duplicates of regions
# Structure is immutable
class SemiIntervalSet
  attr_reader :interval_list
  
  def initialize(*interval_list)
    @interval_list = interval_list.sort 
  rescue
    raise 'Intervals cannot be ordered without intersections'
  end
  
  # gets list of semiintervals, seminterval sets and arrays of semiinterals and their sets
  # returns union of them
  def self.new(*arglist)
    interval_list = arglist.flatten.map(&:interval_list).flatten.reject(&:empty?).uniq
    case interval_list.size
    when 0
      EmptySemiInterval.new # returns EmptySemiInterval instead of empty SemiIntervalSet
    when 1
      interval_list.first # returns SemiInterval (instead of SemiIntervalSet containing the only SemiInterval)
    else
      super(*interval_list)
    end
  end

  def unite_adjacent
    list = []
    interval_list.each{|interval|
      if list.empty?
        list.push(interval)  
        next
      end
      if list.last.adjacent?(interval)
        list.push( list.pop.union(interval) )
      else
        list.push(interval)
      end
    }

    SemiIntervalSet.new(list)
  end
  
  def union(other)
    case other
    when SemiInterval
      intervals_intersecting_other_united = interval_list.select{|interval| interval.intersect?(other) }.inject(other){|result,interval| result.union(interval) }
      SemiIntervalSet.new( interval_list.select{|interval| !interval.intersect?(other)}, intervals_intersecting_other_united )
    when SemiIntervalSet
      other.interval_list.inject(self){|result, interval| result.union(interval) }
    else
      raise 'Unsupported type'
    end
  end
  def intersection(other)
    case other
    when SemiInterval, SemiIntervalSet
      SemiIntervalSet.new( interval_list.map{|interval| other.intersection(interval)} )
    else
      raise 'Unsupported type'
    end
  end
  def subtract(other)
    case other
    when SemiInterval
      SemiIntervalSet.new( interval_list.map{|interval| interval.subtract(other) } )
    when SemiIntervalSet
      other.interval_list.inject(self){|result, interval| result.subtract(interval) }
    else
      raise 'Unsupported type'
    end
  end
  def empty?; false; end
  def contigious?; 
    interval_list.each_cons(2).all?{|region_l, region_r| region_l.adjacent?(region_r) }
  end
  
  def intersect?(other)
    case other
    when SemiInterval, SemiIntervalSet
      interval_list.any?{|interval| other.intersect?(interval)}
    else
      raise 'Unsupported type'
    end
  end
  
  def contain?(other)
    case other
    when SemiInterval
      interval_list.any?{|interval| interval.contain?(other) }
    when SemiIntervalSet
      other.interval_list.all?{|other_interval| self.contain?(other_interval) }
    else
      raise 'Unsupported type'
    end
  end
  def inside?(other)
    case other
    when SemiInterval, SemiIntervalSet
      interval_list.all?{|interval| interval.inside?(other) }
    else
      raise 'Unsupported type'
    end
  end
  def from_left?(other)
    case other
    when SemiInterval, SemiIntervalSet
      self.rightmost_position <= other.leftmost_position
    else
      raise 'Unsupported type'
    end
  end
  def from_right?(other)
    case other
    when SemiInterval, SemiIntervalSet
      other.rightmost_position <= self.leftmost_position
    else
      raise 'Unsupported type'
    end
  end
  
  def ==(other)
    case other
    when SemiIntervalSet
      interval_list == other.interval_list
    when SemiInterval
      false
    else
      raise 'Unsupported type'
    end
  end
  alias_method :eql? , :==
  def hash
    interval_list.hash
  end

  def to_s
    interval_list.map(&:to_s).join('U')
  end
  alias_method :inspect, :to_s
  
  def covering_interval; SemiInterval.new(interval_list.first.pos_start, interval_list.last.pos_end); end
  
  def leftmost_position; interval_list.first.pos_start; end
  def rightmost_position; interval_list.last.pos_end; end
  
  
  alias_method :|, :union
  alias_method :&, :intersection
  alias_method :-, :subtract
end