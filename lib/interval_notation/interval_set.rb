require_relative 'basic_intervals'
require_relative 'error'
require_relative 'operations'

module IntervalNotation
  class IntervalSet
    attr_reader :intervals

    private def check_valid?(intervals)
      intervals.each_cons(2).all? do |interval_1, interval_2|
        interval_1.to <= interval_2.from && !(interval_1.to == interval_2.from && (interval_1.include_to? || interval_2.include_from?))
      end
    end

    def initialize(intervals)
      unless check_valid?(intervals)
        raise Error,  "IntervalSet.new accepts non-overlapping, sorted regions.\nTry to use IntervalNotation.union(...) to create interval from overlapping or not-sorted intervals"
      end
      @intervals = intervals
    end

    
    def self.new_unsafe(intervals)
      obj = allocate
      obj.instance_variable_set(:@intervals, intervals)
      obj
    end

    def to_s
      @intervals.empty? ? "∅" : intervals.map(&:to_s).join('U')
    end

    def inspect; to_s; end

    def include_position?(value)
      interval = @intervals.bsearch{|interv| interv.to >= value }
      interval && interval.include_position?(value)
    end

    # def self.from_string(str)
    # end

    def hash; @intervals.hash; end
    def eql?(other); other.class.equal?(self.class) && intervals == other.intervals; end
    def ==(other); other.is_a?(IntervalSet) && intervals == other.intervals; end
    
    def union(other)
      IntervalNotation.union([self, other])
    end

    def intersection(other)
      IntervalNotation.intersection([self, other])
    end

    def subtract(other)
      IntervalNotation.combine([self, other], SubtractCombiner.new(2))
    end

    def symmetric_difference(other)
      IntervalNotation.combine([self, other], SymmetricDifferenceCombiner.new(2))
    end

    def complement
      R.subtract(self)
    end

    def include?(other)
      other == (self.intersection(other))
    end

    def empty?
      @intervals.empty?
    end

    def intersect?(other)
      !(intersection(other).empty?)
    end

    alias :& :intersection
    alias :| :union
    alias :- :subtract
    alias :^ :symmetric_difference
    alias :~ :complement

  end
  extend Operations
end
