module IntervalAlgebra
  # pos_start and pos_end possibly can be of any class (for example GenomePosition class) but positions should be comparable and pos_start should be less than pos_end
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
        raise ArgumentError, 'Order of ends of an interval changed'
      end
    end

    def contigious?; true; end
    def empty?; false; end
    def length; pos_end - pos_start; end
    def include_position?(pos); (pos_start...pos_end).include?(pos); end

    # self is <mutual_alignment(other)> to other
    def mutual_alignment(other)
      raise UnsupportedType  unless other.is_a?(SemiInterval)
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
        raise InternalError, 'Mutual alignment failed. Logic error: this branch of code should never work'
      end
    end

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
    private :mutual_alignment
    private :intersection_with_region
    private :union_with_region
    private :subtract_with_region

    def intersection(other)
      if other.contigious?
        intersection_with_region(other)
      else
        other.intersection(self)
      end
    end
    def union(other)
      if other.contigious?
        union_with_region(other)
      else
        other.union(self)
      end
    end
    def subtract(other)
      if other.contigious?
        subtract_with_region(other)
      else
        other.interval_list.inject(self){|result, interval| result.subtract(interval) }
      end
    end

    def complement
      SemiInterval.new(-Float::INFINITY, Float::INFINITY) - self
    end

    def intersect?(other)
      ! intersection(other).empty?
    end
    def contain?(other)
      if other.empty?
        true
      elsif other.contigious?
        pos_start <= other.pos_start && other.pos_end <= pos_end
      else
        other.interval_list.all?{|interval| self.contain?(interval)}
      end
    end
    def inside?(other)
      if other.empty?
        false
      elsif other.contigious?
        other.pos_start <= pos_start && pos_end <= other.pos_end
      else
        other.interval_list.any?{|interval| self.inside?(interval)}
      end
    end
    def from_left?(other)
      if other.empty?
        raise ImpossibleComparison, "#{self}.from_left?(#{other}) failed"
      else
        self.rightmost_position <= other.leftmost_position
      end
    end
    def from_right?(other)
      if other.empty?
        raise ImpossibleComparison, "#{self}.from_right?(#{other}) failed"
      else
        other.rightmost_position <= self.leftmost_position
      end
    end
    def region_adjacent?(other)
      if empty? || other.empty?
        raise ImpossibleComparison, "#{self}.region_adjacent?(#{other}) failed"
      elsif other.contigious?
        [:outside_left_adjacent, :outside_right_adjacent].include?  mutual_alignment(other)
      else
        raise UnsupportedType
      end
    end

    def ==(other)
      other.contigious? && !other.empty? && (pos_start == other.pos_start && pos_end == other.pos_end)
    end

    def <=>(other)
      if other.empty?
        raise UnsupportedType
      elsif other.contigious?
        return 0 if self == other
        return -1 if self.from_left?(other)
        return 1 if self.from_right?(other)
        nil
      elsif !other.contigious?
        return -1 if other.interval_list.all?{|interval| self.from_left?(interval)}
        return 1 if other.interval_list.all?{|interval| self.from_right?(interval)}
        nil
      end
    end
    include Comparable

    def eql?(other); self == other; end
    def hash
      [pos_start,pos_end].hash
    end

    def to_s
      "[#{pos_start};#{pos_end})"
    end
    def inspect; to_s; end

    def to_range
      pos_start...pos_end
    end
    def include_position?(pos)
      pos_start <= pos && pos < pos_end
    end

    def interval_list; [self]; end
    def covering_interval; self; end
    def leftmost_position; pos_start; end
    def rightmost_position; pos_end; end

    def |(other); union(other); end
    def &(other); intersection(other); end
    def -(other); subtract(other); end
    def ~; complement; end
  end
end
