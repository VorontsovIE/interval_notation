require_relative 'interval_notation/version'

require_relative 'interval_notation/basic_intervals'
require_relative 'interval_notation/interval_set'

module IntervalNotation
  UNION_SYMBOL = '∪'.freeze
  PLUS_INFINITY_SYMBOL = '+∞'.freeze
  MINUS_INFINITY_SYMBOL = '-∞'.freeze
  EMPTY_SET_SYMBOL = '∅'.freeze

  module Syntax
    module Long
    end
    module Short
    end
  end

  R = IntervalSet.new_unsafe( [OpenOpenInterval.new(-Float::INFINITY, Float::INFINITY)] )
  Empty = IntervalSet.new_unsafe([])

  def oo(from, to)
    IntervalSet.new_unsafe( [OpenOpenInterval.new(from, to)] )
  end

  def co(from, to)
    IntervalSet.new_unsafe( [ClosedOpenInterval.new(from, to)] )
  end

  def oc(from, to)
    IntervalSet.new_unsafe( [OpenClosedInterval.new(from, to)] )
  end

  def cc(from, to)
    IntervalSet.new_unsafe( [ClosedClosedInterval.new(from, to)] )
  end

  def pt(value)
    IntervalSet.new_unsafe( [Point.new(value)] )
  end

  def lt(value)
    IntervalSet.new_unsafe( [OpenOpenInterval.new(-Float::INFINITY, value)] )
  end

  def le(value)
    IntervalSet.new_unsafe( [OpenClosedInterval.new(-Float::INFINITY, value)] )
  end

  def gt(value)
    IntervalSet.new_unsafe( [OpenOpenInterval.new(value, Float::INFINITY)] )
  end

  def ge(value)
    IntervalSet.new_unsafe( [ClosedOpenInterval.new(value, Float::INFINITY)] )
  end

  module_function :oo, :co, :oc, :cc, :pt, :lt, :le, :gt, :ge
end
