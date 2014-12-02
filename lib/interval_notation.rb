require 'interval_notation/version'
require 'interval_notation/basic_intervals'
require 'interval_notation/interval_set'

module IntervalNotation
  R = IntervalSet.new( [OpenOpenInterval.new(-Float::INFINITY, Float::INFINITY)] )
  Empty = IntervalSet.new([])

  def oo(from, to); IntervalSet.new( [OpenOpenInterval.new(from, to)] ); end
  def co(from, to); IntervalSet.new( [ClosedOpenInterval.new(from, to)] ); end
  def oc(from, to); IntervalSet.new( [OpenClosedInterval.new(from, to)] ); end
  def cc(from, to); IntervalSet.new( [ClosedClosedInterval.new(from, to)] ); end
  def pt(value); IntervalSet.new( [Point.new(value)] ); end

  def lt(value); IntervalSet.new( [OpenOpenInterval.new(-Float::INFINITY, value)] ); end
  def le(value); IntervalSet.new( [OpenClosedInterval.new(-Float::INFINITY, value)] ); end
  def gt(value); IntervalSet.new( [OpenOpenInterval.new(value, Float::INFINITY)] ); end
  def ge(value); IntervalSet.new( [ClosedOpenInterval.new(value, Float::INFINITY)] ); end

  module_function :oo, :co, :oc, :cc, :pt, :lt, :le, :gt, :ge
end
