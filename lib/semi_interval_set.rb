class SemiInterval
  attr_reader :pos_start, :pos_end
  def initialize(pos_start, pos_end)
    @pos_start, @pos_end = pos_start, pos_end
  end
  def self.new(pos_start, pos_end)
    raise 'Order of ends of an interval changed'  unless pos_start <= pos_end
    pos_start < pos_end ? super : EmptySemiInterval.new
  end
  def empty?; false; end
  def length; pos_end - pos_start; end
  def include_position?(pos); (pos_start...pos_end).include?(pos); end
  
  # self is <mutual_alignment(other)> to other
  def mutual_alignment(other)
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
    # else
      # raise 'Code can\'t work here'
    end
  end
  def intersection(other)
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
  alias_method :&, :intersection
  
  def union(other)
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
  
  def subtract(other)
    case mutual_alignment(other)
    when :undefined  then self
    when :equal  then EmptySemiInterval.new
    when :inside, :inside_contacted_left, :inside_contacted_right  then EmptySemiInterval.new
    when :contain  then SemiIntervalSet.new( SemiInterval.new(pos_start, other.pos_start), SemiInterval.new(other.pos_end, pos_end) )
    when :left_intersect, :contain_contacted_left then SemiInterval.new(other.pos_end, pos_end)
    when :right_intersect, :contain_contacted_right then SemiInterval.new(pos_start, other.pos_start)
    when :left, :right, :outside_left_adjacent, :outside_right_adjacent  then self
    end
  end
  alias_method :+, :union
  
  def intersect?(other)
    intersection(other).empty?
  end
  def contain?(other)
    [:equal, :contain, :contain_contacted_left, :contain_contacted_right].include?  mutual_alignment(other)
  end
  def inside?(other)
    [:equal, :inside, :inside_contacted_left, :inside_contacted_right].include?  mutual_alignment(other)
  end
  def from_left?(other)
    [:left, :outside_left_adjacent].include?  mutual_alignment(other)
  end
  def from_right?(other)
    [:right, :outside_right_adjacent].include?  mutual_alignment(other)
  end
  def adjacent?(other)
    [:outside_left_adjacent, :outside_right_adjacent].include?  mutual_alignment(other)
  end
  
  def <=>(other)
    return 0 if self == other
    return -1 if self.from_left?(other)
    return 1 if self.from_right?(other)
    nil
  end
  include Comparable
  alias_method :eql? , :==
  def hash
    (pos_start...pos_end).hash
  end
end

class EmptySemiInterval < SemiInterval
  def initialize; end
  def empty?; true; end
  def mutual_alignment(other); other.empty? :equal : :undefined;  end
  def intersection(other); self; end
  def union(other); other; end
  def intersect?(other); false; end
  def contain?(other); false; end
  def inside?(other); true; end ## ??????????????????
  def from_left?(other); true; end ## ??????????????????
  def from_right?(other); true; end ## ??????????????????
  def <=>(other); other.empty? ? 0 : nil; end
  def hash; (:empty).hash; end
  
end

# List of non-intersecting SemiIntervals.
# All empty intervals are rejected during set construction
# Intervals're stored in a sorted list (it's possible because they don't intersect each other)
# Doesn't automatically unite adjacent SemiIntervals(but you can make it manually)
# Structure is immutable
class SemiIntervalSet
  attr_reader :interval_list
  # gets list of semiintervals, seminterval sets and arrays of semiinterals and their sets
  # returns union of them
  def initialize(*interval_list)
    list = []
    interval_list.flatten.each do |sublist|
      case sublist
      when SemiInterval
        list.push(sublist)
      when SemiIntervalList
        list.concat(sublist.interval_list)
      else
        raise "Unsupported type of element in SemiIntervalSet construction: #{sublist}"
      end
    end
    list.reject!(&:empty?)
    list.sort!  rescue raise 'Intervals cannot be ordered without intersections'
  end
  
  def unite_adjacent
    list = []
    interval_list.each{|interval|
      list.push(interval)  if list.empty?
      if list.last.adjacent?(interval)
        list.push( list.pop.union(interval) )
      else
        list.push(interval)
      end
    }
    SemiIntervalSet.new(result)
  end
  
  def union(other)
    case other
    when SemiInterval, SemiIntervalSet
      interval_list.inject(self){|result, interval| result.union(interval) }
    else
      raise 'Unsupported type'
    end
  end
  def intersect(other)
    case other
    when SemiInterval
      SemiIntervalSet.new( interval_list.map{|interval| interval.intersection(other)} )
    when SemiIntervalSet
      SemiIntervalSet.new( interval_list.map{|interval| self.intersection(interval)} )
    else
      raise 'Unsupported type'
    end
  end
  def subtract(other)
    SemiInterval.new( interval_list.map{|interval| interval.subtract(other) } )
  end
  def empty?
    interval_list.empty?
  end
end

#   list of intervals, 
#   #compact (unites overlapping regions)
#   #sort
