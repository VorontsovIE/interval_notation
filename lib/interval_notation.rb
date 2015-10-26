require_relative 'interval_notation/version'

require_relative 'interval_notation/error'
require_relative 'interval_notation/basic_intervals'
require_relative 'interval_notation/combiners'
require_relative 'interval_notation/interval_set'
require_relative 'interval_notation/operations'

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

      def oo_basic(from, to)
        BasicIntervals::OpenOpenInterval.new(from, to)
      end

      def co_basic(from, to)
        BasicIntervals::ClosedOpenInterval.new(from, to)
      end

      def oc_basic(from, to)
        BasicIntervals::OpenClosedInterval.new(from, to)
      end

      def cc_basic(from, to)
        if from != to
          BasicIntervals::ClosedClosedInterval.new(from, to)
        else
          BasicIntervals::Point.new(from)
        end
      end

      def pt_basic(value)
        BasicIntervals::Point.new(value)
      end

      def lt_basic(value)
        BasicIntervals::OpenOpenInterval.new(-Float::INFINITY, value)
      end

      def le_basic(value)
        BasicIntervals::OpenClosedInterval.new(-Float::INFINITY, value)
      end

      def gt_basic(value)
        BasicIntervals::OpenOpenInterval.new(value, Float::INFINITY)
      end

      def ge_basic(value)
        BasicIntervals::ClosedOpenInterval.new(value, Float::INFINITY)
      end

      module_function :oo_basic, :co_basic, :oc_basic, :cc_basic, :pt_basic, :lt_basic, :le_basic, :gt_basic, :ge_basic

      def interval(str)
        IntervalSet.from_string(str)
      end

      def oo(from, to);  IntervalSet.new_unsafe( [oo_basic(from, to)] );  end
      def co(from, to);  IntervalSet.new_unsafe( [co_basic(from, to)] );  end
      def oc(from, to);  IntervalSet.new_unsafe( [oc_basic(from, to)] );  end
      def cc(from, to);  IntervalSet.new_unsafe( [cc_basic(from, to)] );  end
      def pt(value);  IntervalSet.new_unsafe( [pt_basic(value)] );  end
      def lt(value);  IntervalSet.new_unsafe( [lt_basic(value)] );  end
      def le(value);  IntervalSet.new_unsafe( [le_basic(value)] );  end
      def gt(value);  IntervalSet.new_unsafe( [gt_basic(value)] );  end
      def ge(value);  IntervalSet.new_unsafe( [ge_basic(value)] );  end
      module_function :oo, :co, :oc, :cc, :pt, :lt, :le, :gt, :ge, :interval
    end

    # Long syntax for interval factory methods
    module Long
      R = ::IntervalNotation::R
      Empty = ::IntervalNotation::Empty

      def open_open_basic(from, to)
        BasicIntervals::OpenOpenInterval.new(from, to)
      end

      def closed_open_basic(from, to)
        BasicIntervals::ClosedOpenInterval.new(from, to)
      end

      def open_closed_basic(from, to)
        BasicIntervals::OpenClosedInterval.new(from, to)
      end

      def closed_closed_basic(from, to)
        if from != to
          BasicIntervals::ClosedClosedInterval.new(from, to)
        else
          BasicIntervals::Point.new(from)
        end
      end

      def point_basic(value)
        BasicIntervals::Point.new(value)
      end

      def less_than_basic(value)
        BasicIntervals::OpenOpenInterval.new(-Float::INFINITY, value)
      end

      def less_than_or_equal_to_basic(value)
        BasicIntervals::OpenClosedInterval.new(-Float::INFINITY, value)
      end

      def greater_than_basic(value)
        BasicIntervals::OpenOpenInterval.new(value, Float::INFINITY)
      end

      def greater_than_or_equal_to_basic(value)
        BasicIntervals::ClosedOpenInterval.new(value, Float::INFINITY)
      end

      module_function :open_open_basic, :closed_open_basic, :open_closed_basic, :closed_closed_basic, :point_basic,
                      :less_than_basic, :less_than_or_equal_to_basic, :greater_than_basic, :greater_than_or_equal_to_basic

      def interval(str)
        IntervalSet.from_string(str)
      end

      def open_open(from, to);  IntervalSet.new_unsafe([ open_open_basic(from, to) ]);  end
      def closed_open(from, to);  IntervalSet.new_unsafe([ closed_open_basic(from, to) ]);  end
      def open_closed(from, to);  IntervalSet.new_unsafe([ open_closed_basic(from, to) ]);  end
      def closed_closed(from, to);  IntervalSet.new_unsafe([ closed_closed_basic(from, to) ]);  end
      def point(value);  IntervalSet.new_unsafe([ point_basic(value) ]);  end
      def less_than(value);  IntervalSet.new_unsafe([ less_than_basic(value) ]);  end
      def less_than_or_equal_to(value);  IntervalSet.new_unsafe([ less_than_or_equal_to_basic(value) ]);  end
      def greater_than(value);  IntervalSet.new_unsafe([ greater_than_basic(value) ]);  end
      def greater_than_or_equal_to(value);  IntervalSet.new_unsafe([ greater_than_or_equal_to_basic(value) ]);  end

      module_function :open_open, :closed_open, :open_closed, :closed_closed, :point,
                      :less_than, :less_than_or_equal_to, :greater_than, :greater_than_or_equal_to,
                      :interval
    end
  end
end
