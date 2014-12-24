require_relative 'error'

module IntervalNotation
  module BasicIntervals
    # Auxiliary class to represent information about interval boundaries
    BoundaryPoint = Struct.new(:value, :included, :opening, :interval_index, :interval_boundary) do
      def closing
        !opening
      end
    end

    module ActslikeInterval
      def self.included(base)
        base.class_eval do
          attr_reader :from, :to
        end
      end

      def from_finite?; from.to_f.finite?; end
      def to_finite?; to.to_f.finite?; end
      def finite?; from_finite? && to_finite?; end

      def from_to_s; from_finite? ? from : MINUS_INFINITY_SYMBOL; end
      def to_to_s; to_finite? ? to : PLUS_INFINITY_SYMBOL; end

      def length; to - from; end
      def inspect; to_s; end
      def singular_point?; false; end
      def hash; [@from, @to, include_from?, include_to?].hash; end;
      def eql?(other); other.class.equal?(self.class) && from.eql?(other.from) && to.eql?(other.to); end
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
      def to_to_s; to; end

      def include_position?(value); from < value && value <= to; end
      def ==(other); other.is_a?(OpenClosedInterval) && from == other.from && to == other.to; end
      def interval_boundaries(interval_index)
        [ BoundaryPoint.new(from, false, true, interval_index, true),
          BoundaryPoint.new(to, true, false, interval_index, true) ]
      end
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
      def from_to_s; from; end

      def include_position?(value); from <= value && value < to; end
      def ==(other); other.is_a?(ClosedOpenInterval) && from == other.from && to == other.to; end
      def interval_boundaries(interval_index)
        [ BoundaryPoint.new(from, true, true, interval_index, true),
          BoundaryPoint.new(to, false, false, interval_index, true) ]
      end
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
      def from_to_s; from; end
      def to_to_s; to; end

      def include_position?(value); from <= value && value <= to; end
      def ==(other); other.is_a?(ClosedClosedInterval) && from == other.from && to == other.to; end
      def interval_boundaries(interval_index)
        [ BoundaryPoint.new(from, true, true, interval_index, true),
          BoundaryPoint.new(to, true, false, interval_index, true) ]
      end
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

      def from_finite?; true; end
      def to_finite?; true; end
      def finite?; true; end

      def length; 0; end
      def to_s; "{#{@value}}"; end
      def inspect; to_s; end

      def include_from?; true; end
      def include_to?; true; end

      def singular_point?; true; end
      def include_position?(val); value == val; end
      def hash; @value.hash; end;
      def eql?(other); other.class.equal?(self.class) && value == other.value; end
      def ==(other); other.is_a?(Point) && value == other.value; end
      def interval_boundaries(interval_index)
        BoundaryPoint.new(from, true, nil, interval_index, false)
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

  end
end
