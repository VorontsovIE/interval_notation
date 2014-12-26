require 'benchmark'
require_relative '../lib/interval_notation'
include IntervalNotation::Syntax::Long

num_intervals_to_unite = 10_000
srand(13)
random_intervals_1 = num_intervals_to_unite.times.map{|i| 2.times.map{ 0.3*i + rand }.sort }.reject{|a,b| a==b }.map{|a,b| closed_closed(a,b)  }
random_intervals_2 = num_intervals_to_unite.times.map{|i| 2.times.map{ 3000 + 0.3*i + rand }.sort }.reject{|a,b| a==b }.map{|a,b| closed_closed(a,b)  }

N = 100
M = 100_000

dispersed_interval_1 = IntervalNotation::Operations.union(random_intervals_1)
dispersed_interval_2 = IntervalNotation::Operations.union(random_intervals_2)

singular_interval_1 = closed_closed(500 + rand, 1000 + rand)
singular_interval_2 = closed_closed(700 + rand, 1700 + rand)

Benchmark.bm do |benchmark_report|


  benchmark_report.report("intersect? dispersed intervals to singular interval (#{M} times)") do
    M.times do
      dispersed_interval_1.intersect?(singular_interval_1)
    end
  end

  benchmark_report.report("intersect? singular interval to dispersed intervals (#{M} times)") do
    M.times do
      singular_interval_1.intersect?(dispersed_interval_1)
    end
  end

  benchmark_report.report("intersect? two dispersed intervals (#{M} times)") do
    M.times do
      dispersed_interval_2.intersect?(dispersed_interval_1)
      dispersed_interval_1.intersect?(dispersed_interval_2)
    end
  end

  benchmark_report.report("Unite #{num_intervals_to_unite} intervals (#{N} times)") do
    N.times do
      IntervalNotation::Operations.union(random_intervals_1)
    end
  end
end
