require 'rspec'

require_relative '../lib/interval_notation'

include IntervalNotation
include IntervalNotation::BasicIntervals
include IntervalNotation::Syntax::Short

def interval_for_each_boundary_type(from, to)
  return enum_for(:interval_for_each_boundary_type, from, to)  unless block_given?
  [true, false].product([true,false]).each do |include_from, include_to|
    yield BasicIntervals.interval_by_boundary_inclusion(include_from, from, include_to, to).to_interval_set
  end
end


def pairs_of_intervals_for_each_boundary_with_answer(from_1, to_1, from_2, to_2, answer)
  interval_for_each_boundary_type(from_1, to_1).flat_map { |interval_1|
    interval_for_each_boundary_type(from_2, to_2).map { |interval_2|
      [[interval_1, interval_2], answer]
    }
  }
end

def each_combination_of_intervals(intervals)
  basic_intervals = intervals.flat_map(&:intervals)
  (1..basic_intervals.size / 2).each do |chunk_1_size|
    indices = basic_intervals.size.times.to_a
    indices.combination(chunk_1_size).each do |chunk_1_indices|
      chunk_2_indices = indices - chunk_1_indices
      chunk_1 = IntervalNotation::Operations.union(chunk_1_indices.map{|i| IntervalSet.new([basic_intervals[i]]) })
      chunk_2 = IntervalNotation::Operations.union(chunk_2_indices.map{|i| IntervalSet.new([basic_intervals[i]]) })
      yield chunk_1, chunk_2
    end
  end
end
