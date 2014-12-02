$:.unshift File.expand_path('../lib/',__dir__)
require 'interval_notation'
require 'benchmark'

include IntervalNotation
i1 = oo(1,3) | pt(8) | oc(4.2,7.3) | gt(100) | le(-67.5)
i2 = oo(-1,2.75) | pt(3) | pt(2.86) | oc(-7.3,-4.2) | ge(120) | cc(6,9) | lt(-67.5)

int_1 = OpenOpenInterval.new(26,27)
int_2 = OpenOpenInterval.new(13,26)
int_3 = OpenClosedInterval.new(-1,13)
int_4 = OpenClosedInterval.new(-100,-70)

# GC.disable
n = 100_000
m = 10_000_000
# puts "#{n} iterations"

Benchmark.bm do |x|
  x.report("OpenOpenInterval") do
    m.times { OpenOpenInterval.new(2,6) }
  end
  x.report("IntervalSet") do
    # m.times { IntervalSet.new([int_1,int_2,int_3,int_4]) }
    m.times { IntervalSet.new([int_4,int_3,int_2,int_1,]) }
  end
  x.report "i1 == i2" do
    m.times { i1 == i2 }
  end
  x.report "i1 include_position?(1)" do
    m.times{ i1.include_position?(1) }
  end
  x.report "i1 include?(i2)" do
    n.times{ i1.include?(i2) }
  end

  x.report "i1 | i2" do
    n.times{ i1|i2 }
  end
  x.report "i1 & i2" do
    n.times{ i1&i2 }
  end
end
