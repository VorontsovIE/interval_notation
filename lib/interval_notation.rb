require_relative 'interval_notation/version'

require_relative 'interval_notation/basic_intervals'
require_relative 'interval_notation/interval_set'

module IntervalNotation
  UNION_SYMBOL = '∪'.freeze
  PLUS_INFINITY_SYMBOL = '+∞'.freeze
  MINUS_INFINITY_SYMBOL = '-∞'.freeze
  EMPTY_SET_SYMBOL = '∅'.freeze

  R = IntervalSet.new_unsafe( [BasicIntervals::OpenOpenInterval.new(-Float::INFINITY, Float::INFINITY)] )
  Empty = IntervalSet.new_unsafe([])

  module Syntax
    # Long syntax for interval factory methods
    module Short
      R = ::IntervalNotation::R
      Empty = ::IntervalNotation::Empty

      def oo(from, to)
        IntervalSet.new_unsafe( [BasicIntervals::OpenOpenInterval.new(from, to)] )
      end

      def co(from, to)
        IntervalSet.new_unsafe( [BasicIntervals::ClosedOpenInterval.new(from, to)] )
      end

      def oc(from, to)
        IntervalSet.new_unsafe( [BasicIntervals::OpenClosedInterval.new(from, to)] )
      end

      def cc(from, to)
        IntervalSet.new_unsafe( [BasicIntervals::ClosedClosedInterval.new(from, to)] )
      end

      def pt(value)
        IntervalSet.new_unsafe( [BasicIntervals::Point.new(value)] )
      end

      def lt(value)
        IntervalSet.new_unsafe( [BasicIntervals::OpenOpenInterval.new(-Float::INFINITY, value)] )
      end

      def le(value)
        IntervalSet.new_unsafe( [BasicIntervals::OpenClosedInterval.new(-Float::INFINITY, value)] )
      end

      def gt(value)
        IntervalSet.new_unsafe( [BasicIntervals::OpenOpenInterval.new(value, Float::INFINITY)] )
      end

      def ge(value)
        IntervalSet.new_unsafe( [BasicIntervals::ClosedOpenInterval.new(value, Float::INFINITY)] )
      end

      module_function :oo, :co, :oc, :cc, :pt, :lt, :le, :gt, :ge
    end

    # Long syntax for interval factory methods
    module Long
      R = ::IntervalNotation::R
      Empty = ::IntervalNotation::Empty

      def open_open(from, to)
        IntervalSet.new_unsafe( [BasicIntervals::OpenOpenInterval.new(from, to)] )
      end

      def closed_open(from, to)
        IntervalSet.new_unsafe( [BasicIntervals::ClosedOpenInterval.new(from, to)] )
      end

      def open_closed(from, to)
        IntervalSet.new_unsafe( [BasicIntervals::OpenClosedInterval.new(from, to)] )
      end

      def closed_closed(from, to)
        IntervalSet.new_unsafe( [BasicIntervals::ClosedClosedInterval.new(from, to)] )
      end

      def point(value)
        IntervalSet.new_unsafe( [BasicIntervals::Point.new(value)] )
      end

      def less_than(value)
        IntervalSet.new_unsafe( [BasicIntervals::OpenOpenInterval.new(-Float::INFINITY, value)] )
      end

      def less_than_or_equal_to(value)
        IntervalSet.new_unsafe( [BasicIntervals::OpenClosedInterval.new(-Float::INFINITY, value)] )
      end

      def greater_than(value)
        IntervalSet.new_unsafe( [BasicIntervals::OpenOpenInterval.new(value, Float::INFINITY)] )
      end

      def greater_than_or_equal_to(value)
        IntervalSet.new_unsafe( [BasicIntervals::ClosedOpenInterval.new(value, Float::INFINITY)] )
      end

      module_function :open_open, :closed_open, :open_closed, :closed_closed, :point,
                      :less_than, :less_than_or_equal_to, :greater_than, :greater_than_or_equal_to
    end
  end
end
