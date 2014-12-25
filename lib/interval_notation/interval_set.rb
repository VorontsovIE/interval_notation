require_relative 'basic_intervals'
require_relative 'error'
require_relative 'operations'

module IntervalNotation
  class IntervalSet
    attr_reader :intervals

    # +IntervalSet.new+ accepts an ordered list of intervals.
    # Intervals should be sorted from leftmost to rightmost and should not overlap.
    # It's not recommended to use this constructor directly. Instead take a look at +IntervalNotation::Syntax+ module.
    #
    # Example:
    #   # don't use this
    #   IntervalSet.new([OpenOpenInterval.new(1,3), Point.new(5)])
    #   # instead use
    #   oo(1,3) | pt(5)

    def initialize(intervals)
      unless IntervalSet.check_valid?(intervals)
        raise Error,  "IntervalSet.new accepts non-overlapping, sorted regions.\n" +
                      "Try to use IntervalNotation.union(...) to create interval from overlapping or not-sorted intervals"
      end
      @intervals = intervals.freeze
    end

    # Method to create an interval set from string.
    # It accepts strings obtained by +#to_s+ and many other formats.
    # Spaces inside are ignored
    # Intervals can be joined with +u+ or +U+ letters and unicode union character +∪+
    # Points can go separately or be combined inside of single curly braces. Single point can go without braces at all
    # +,+ and +;+ are both valid value separators.
    # Infinity can be represented by +inf+, +infty+, +\infty+, +infinity+, +∞+ (each can go with or without sign)
    # Empty set is empty string, word +Empty+ or unicode character +∅+
    # +R+ represents whole 1-D line (-∞, ∞)
    def self.from_string(str)
      intervals = str.split(/[uU∪]/).flat_map{|interval_str|
        BasicIntervals.from_string(interval_str)
      }.map(&:to_interval_set)
      Operations.union(intervals)
    end

    # Output standard mathematical notation of interval set in left-to-right order.
    # Each singular point is listed separately in curly braces.
    def to_s
      @intervals.empty? ? EMPTY_SET_SYMBOL : intervals.map(&:to_s).join(UNION_SYMBOL)
    end

    def inspect # :nodoc:
      to_s
    end

    # Checks whether an interval set contains certain position.
    # Operation complexity is O(ln N), where N is a number of contiguous regions in an interval set
    def include_position?(value)
      interval = @intervals.bsearch{|interv| interv.to >= value }
      interval && interval.include_position?(value)
    end

    # Checks whether an interval set contains another interval set. Alias: +#include?+
    def contain?(other)
      self.intersection(other) == other
    end
    alias include? contain?

    # Checks whether an interval set is covered by another interval set. Alias: +#covered_by?+
    def contained_by?(other)
      self.intersection(other) == self
    end
    alias covered_by? contained_by?

    # TODO: optimize if possible.
    # Checks whether an interval set intersects another interval set. Alias: +#intersect?+
    def intersect?(other)
      ! intersection(other).empty?
    end
    alias overlap? intersect?

    # Checks whether an interval set is empty
    def empty?
      @intervals.empty?
    end

    # Checks whether an interval set is contiguous (empty set treated contiguous)
    def contiguous?
      @intervals.size <= 1
    end

    # Total length of all intervals in set
    def total_length
      @intervals.map(&:length).inject(0, &:+)
    end

    # Number of connected components
    def num_connected_components
      @intervals.size
    end

    # TODO: optimize.
    # Closure of an interval set
    def closure
      Operations.union(@intervals.map(&:closure).map(&:to_interval_set))
    end

    # Minimal contiguous interval, covering interval set
    def covering_interval
      if @intervals.size == 0
        Empty
      elsif @intervals.size == 1
        self
      else
        BasicIntervals.interval_by_boundary_inclusion(@intervals.first.include_from?, @intervals.first.from,
                                                      @intervals.last.include_to?, @intervals.last.to).to_interval_set
      end
    end

    def hash # :nodoc:
      @intervals.hash
    end

    def eql?(other) # :nodoc:
      other.class.equal?(self.class) && intervals == other.intervals
    end

    # Intervals are equal only if they contain exactly the same intervals.
    # Point inclusion is also considered
    def ==(other)
      other.is_a?(IntervalSet) && intervals == other.intervals
    end

    # Union of an interval set with another interval set +other+. Alias: +|+
    # To unite many (tens of thousands intervals) intervals use +IntervalNotation::Operations.unite+ method.
    # (+Operations.unite+ is dramatically faster than sequentially uniting intervals one-by-one)
    def union(other)
      Operations.union([self, other])
    end

    # Intersection of an interval set with another interval set +other+. Alias: +&+
    # To unite many (tens of thousands intervals) intervals use +IntervalNotation::Operations.intersection+ method.
    # (+Operations.intersection+ is dramatically faster than sequentially intersecting intervals one-by-one)
    def intersection(other)
      Operations.intersection([self, other])
    end

    # Difference between an interval set and another interval set +other+. Alias: +-+
    def subtract(other)
      Operations.combine([self, other], SubtractCombiner.new)
    end

    # Symmetric difference between an interval set and another interval set +other+. Alias: +^+
    def symmetric_difference(other)
      Operations.combine([self, other], SymmetricDifferenceCombiner.new)
    end

    # Complement of an interval set in R. Alias: +~+
    def complement
      R.subtract(self)
    end

    alias :& :intersection
    alias :| :union
    alias :- :subtract
    alias :^ :symmetric_difference
    alias :~ :complement


    # Auxiliary method to share part of common interface with basic intervals
    def to_interval_set # :nodoc:
      self
    end

    class << self
      # auxiliary method to check that intervals are sorted and don't overlap
      def check_valid?(intervals)
        intervals.each_cons(2).all? do |interval_1, interval_2|
          interval_1.to <= interval_2.from && !(interval_1.to == interval_2.from && (interval_1.include_to? || interval_2.include_from?))
        end
      end

      # An +IntervalSet.new_unsafe+ is a constructor which skips validation. It's designed mostly for internal use.
      # It can be used when you are absolutely sure, that intervals are ordered and don't overlap.
      def new_unsafe(intervals)
        obj = allocate
        obj.instance_variable_set(:@intervals, intervals.freeze)
        obj
      end
    end
  end
  extend Operations
end
