require_relative 'error'
require_relative 'interval_set'

module IntervalNotation
  module BasicIntervals # :nodoc: all
    # Auxiliary class to represent information about interval boundaries
    BoundaryPoint = Struct.new(:value, :included, :opening, :interval_index, :interval_boundary) do
      def closing
        !opening
      end
      def singular_point?
        !interval_boundary
      end
    end

    module ActslikeInterval
      def self.included(base)
        base.class_eval do
          attr_reader :from, :to
        end
      end

      def closure
        if from_finite?
          if to_finite?
            ClosedClosedInterval.new(from, to)
          else
            ClosedOpenInterval.new(from, to) # to == +∞
          end
        else
          if to_finite?
            OpenClosedInterval.new(from, to)  # from == -∞
          else
            OpenOpenInterval.new(from, to)  # from == -∞, to == +∞
          end
        end
      end

      def to_interval_set; IntervalSet.new([self]); end

      def from_finite?; from.to_f.finite?; end
      def to_finite?; to.to_f.finite?; end
      def finite?; from_finite? && to_finite?; end
      def from_infinite?; from.to_f.infinite?; end
      def to_infinite?; to.to_f.infinite?; end
      def infinite?; from_infinite? || to_infinite?; end

      def from_to_s; from_finite? ? from : MINUS_INFINITY_SYMBOL; end
      def to_to_s; to_finite? ? to : PLUS_INFINITY_SYMBOL; end

      def length; to - from; end
      def inspect; to_s; end
      def singular_point?; false; end
      def hash; [@from, @to, include_from?, include_to?].hash; end;
      def eql?(other); other.class.equal?(self.class) && from.eql?(other.from) && to.eql?(other.to); end

      # include position and its vicinity
      def deep_include_position?(pos)
        from < pos && pos < to
      end
    end

    class OpenOpenInterval
      include ActslikeInterval
      def initialize(from, to)
        raise Error, "Interval (#{from};#{to}) can't be created"  unless from < to
        @from = from
        @to = to
      end
      def to_s; "(#{from_to_s};#{to_to_s})"; end
      def include_from?; false; end
      def include_to?; false; end
      def include_position?(value); from < value && value < to; end
      def ==(other); other.is_a?(OpenOpenInterval) && from == other.from && to == other.to; end
      def interval_boundaries(interval_index)
        [ BoundaryPoint.new(from, false, true, interval_index, true),
          BoundaryPoint.new(to, false, false, interval_index, true) ]
      end

      # ToDo: fix integer_points for case of infinite boundary
      def integer_points; (from + 1).floor .. (to - 1).ceil; end
    end

    class OpenClosedInterval
      include ActslikeInterval
      def initialize(from, to)
        raise Error, "Interval (#{from};#{to}] can't be created"  unless from < to
        raise Error, "Infinite boundary should be open" unless to.to_f.finite?
        @from = from
        @to = to
      end
      def to_s; "(#{from_to_s};#{to_to_s}]"; end
      def include_from?; false; end
      def include_to?; true; end

      def to_finite?; true; end
      def to_infinite?; false; end
      def to_to_s; to; end

      def closure
        if from_finite?
          ClosedClosedInterval.new(from, to)
        else
          OpenClosedInterval.new(from, to)  # from == -∞
        end
      end

      def include_position?(value); from < value && value <= to; end
      def ==(other); other.is_a?(OpenClosedInterval) && from == other.from && to == other.to; end
      def interval_boundaries(interval_index)
        [ BoundaryPoint.new(from, false, true, interval_index, true),
          BoundaryPoint.new(to, true, false, interval_index, true) ]
      end

      # ToDo: fix integer_points for case of infinite boundary
      def integer_points; (from + 1).floor .. to.floor; end
    end

    class ClosedOpenInterval
      include ActslikeInterval
      def initialize(from, to)
        raise Error, "Interval [#{from};#{to}) can't be created"  unless from < to
        raise Error, "Infinite boundary should be open" unless from.to_f.finite?
        @from = from
        @to = to
      end
      def to_s; "[#{from_to_s};#{to_to_s})"; end
      def include_from?; true; end
      def include_to?; false; end

      def from_finite?; true; end
      def from_infinite?; false; end
      def from_to_s; from; end

      def closure
        if to_finite?
          ClosedClosedInterval.new(from, to)
        else
          ClosedOpenInterval.new(from, to) # to == +∞
        end
      end

      def include_position?(value); from <= value && value < to; end
      def ==(other); other.is_a?(ClosedOpenInterval) && from == other.from && to == other.to; end
      def interval_boundaries(interval_index)
        [ BoundaryPoint.new(from, true, true, interval_index, true),
          BoundaryPoint.new(to, false, false, interval_index, true) ]
      end

      # ToDo: fix integer_points for case of infinite boundary
      def integer_points; from.ceil .. (to - 1).ceil; end
    end

    class ClosedClosedInterval
      include ActslikeInterval
      def initialize(from, to)
        raise Error, "Interval [#{from};#{to}] can't be created"  unless from < to
        raise Error, "Infinite boundary should be open" unless from.to_f.finite? && to.to_f.finite?
        @from = from
        @to = to
      end
      def to_s; "[#{from_to_s};#{to_to_s}]"; end
      def include_from?; true; end
      def include_to?; true; end

      def from_finite?; true; end
      def to_finite?; true; end
      def finite?; true; end
      def from_infinite?; false; end
      def to_infinite?; false; end
      def infinite?; false; end
      def from_to_s; from; end
      def to_to_s; to; end

      def closure; self; end

      def include_position?(value); from <= value && value <= to; end
      def ==(other); other.is_a?(ClosedClosedInterval) && from == other.from && to == other.to; end
      def interval_boundaries(interval_index)
        [ BoundaryPoint.new(from, true, true, interval_index, true),
          BoundaryPoint.new(to, true, false, interval_index, true) ]
      end

      def integer_points; from.ceil .. to.floor; end
    end

    class Point
      attr_reader :value
      protected :value
      def initialize(value)
        raise Error, "Point can't represent an infinity"  unless value.to_f.finite?
        @value = value
      end
      def from; value; end
      def to; value; end

      def to_interval_set; IntervalSet.new([self]); end

      def from_finite?; true; end
      def to_finite?; true; end
      def finite?; true; end
      def from_infinite?; false; end
      def to_infinite?; false; end
      def infinite?; false; end

      def length; 0; end
      def to_s; "{#{@value}}"; end
      def inspect; to_s; end

      def include_from?; true; end
      def include_to?; true; end

      def closure; self; end

      def singular_point?; true; end
      def include_position?(val); value == val; end
      def hash; @value.hash; end;
      def eql?(other); other.class.equal?(self.class) && value == other.value; end
      def ==(other); other.is_a?(Point) && value == other.value; end
      def interval_boundaries(interval_index)
        [BoundaryPoint.new(from, true, nil, interval_index, false)]
      end

      # ToDo: fix integer_points for point not to yield a point itself when it isn't integer
      def integer_points; value..value; end

      # include position and its vicinity (point can't include vicinity of a position)
      def deep_include_position?(pos)
        false
      end
    end

    def self.interval_by_boundary_inclusion(include_from, from, include_to, to)
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

    PLUS_INFINITY_VARIANTS = ['∞', 'inf', 'infinity', 'infty', '\infty', '+∞', '+inf', '+infinity', '+infty', '+\infty']
    MINUS_INFINITY_VARIANTS = ['-∞', '-inf', '-infinity', '-infty', '-\infty']
    EMPTY_VARIANTS = ['∅','empty','']
    OPENING_VARIANTS = ['(','[']
    CLOSING_VARIANTS = [')',']']

    # returns an Interval (wrapped or unwrapped) or an array of Points or empty list (for Empty interval)
    def self.from_string(interval_str)
      interval_str = interval_str.gsub(/\s/,'')
      return Empty  if EMPTY_VARIANTS.include?(interval_str.downcase)
      return R  if interval_str == 'R'
      if interval_str[0] == '{' && interval_str[-1] == '}'
        interval_str[1..-2].split(/[,;]/).map{|el| Point.new(Float(el)) }
      elsif OPENING_VARIANTS.include?(interval_str[0]) && CLOSING_VARIANTS.include?(interval_str[-1])
        boundary_values = interval_str[1..-2].split(/[,;]/).map(&:strip)
        raise Error, 'Unknown format'  unless boundary_values.size == 2
        from = (MINUS_INFINITY_VARIANTS.include?(boundary_values[0].downcase)) ? -Float::INFINITY : Float(boundary_values[0])
        to   = (PLUS_INFINITY_VARIANTS.include?(boundary_values[1].downcase)) ? Float::INFINITY : Float(boundary_values[1])

        if interval_str[0] == '('
          if interval_str[-1] == ')'
            OpenOpenInterval.new(from, to)
          elsif interval_str[-1] == ']'
            OpenClosedInterval.new(from, to)
          else
            raise Error, 'Unknown format'
          end
        elsif interval_str[0] == '['
          if interval_str[-1] == ')'
            ClosedOpenInterval.new(from, to)
          elsif interval_str[-1] == ']'
            ClosedClosedInterval.new(from, to)
          else
            raise Error, 'Unknown format'
          end
        else
          raise Error, 'Unknown format'
        end
      else
        begin
          Point.new(Float(interval_str))
        rescue
          raise Error, 'Unknown format'
        end
      end
    end

  end
end
