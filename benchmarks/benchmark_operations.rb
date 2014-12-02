$:.unshift File.expand_path('../lib/',__dir__)
require 'interval_notation'
require 'benchmark'

include IntervalNotation
i1 = oo(1,3) | pt(8) | oc(4.2,7.3) | gt(100) | le(-67.5)
i2 = oo(-1,2.75) | pt(3) | pt(2.86) | oc(-7.3,-4.2) | ge(120) | cc(6,9) | lt(-67.5)

# GC.disable
n = 100_000
m = 10_000_000
# puts "#{n} iterations"

Benchmark.bm do |x|
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
