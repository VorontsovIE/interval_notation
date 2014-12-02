require 'interval_notation/version'
require 'interval_notation/basic_intervals'
require 'interval_notation/interval_set'

module IntervalNotation
  R = OpenOpenInterval.new(-Float::INFINITY, Float::INFINITY)

  def oo(from, to); OpenOpenInterval.new(from, to); end
  def co(from, to); ClosedOpenInterval.new(from, to); end
  def oc(from, to); OpenClosedInterval.new(from, to); end
  def cc(from, to); ClosedClosedInterval.new(from, to); end
  def pt(value); Point.new(value); end

  def lt(value); OpenOpenInterval.new(-Float::INFINITY, value); end
  def le(value); OpenClosedInterval.new(-Float::INFINITY, value); end
  def gt(value); OpenOpenInterval.new(value, Float::INFINITY); end
  def ge(value); ClosedOpenInterval.new(value, Float::INFINITY); end

  def inttree(*intervals); IntervalSet.new(intervals); end

  module_function :oo, :co, :oc, :cc, :pt, :lt, :le, :gt, :ge
  module_function :inttree
end
