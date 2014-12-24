require 'interval_notation'

include IntervalNotation
include IntervalNotation::BasicIntervals
include IntervalNotation::Syntax::Short

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

describe IntervalNotation do
  describe IntervalSet do
    describe '.new' do
      [ [OpenOpenInterval.new(1,3)],
        [ClosedOpenInterval.new(1,3)],
        [OpenClosedInterval.new(1,3)],
        [ClosedClosedInterval.new(1,3)],
        [Point.new(3)],
        [OpenOpenInterval.new(-Float::INFINITY, 1)],
        [OpenOpenInterval.new(-Float::INFINITY, 1), OpenOpenInterval.new(2,3)],
        [OpenOpenInterval.new(10, Float::INFINITY)],
        [OpenOpenInterval.new(2,3), OpenOpenInterval.new(10, Float::INFINITY)],
        [OpenOpenInterval.new(1,3), Point.new(4)],
        [OpenOpenInterval.new(1,3), OpenOpenInterval.new(3,6)],
        [OpenOpenInterval.new(1,3), OpenOpenInterval.new(4,6)],
        [OpenOpenInterval.new(1,3), ClosedOpenInterval.new(4,6)],
        [OpenClosedInterval.new(1,3), OpenOpenInterval.new(4,6)],
        [OpenClosedInterval.new(1,3), ClosedOpenInterval.new(4,6)],
        [ClosedClosedInterval.new(1,3), ClosedClosedInterval.new(4,6)],
        [OpenOpenInterval.new(1,3), OpenOpenInterval.new(3,6), ClosedClosedInterval.new(7,10), Point.new(11)]
      ].each do |intervals|
        it("IntervalSet.new(#{intervals.map(&:to_s).join(',')}) should not fail") do
          expect{ IntervalSet.new(intervals) }.not_to raise_error
        end
      end

      [ [OpenOpenInterval.new(3,6), OpenOpenInterval.new(1,3)],
        [OpenOpenInterval.new(1,3), Point.new(1)],
        [OpenOpenInterval.new(1,3), Point.new(0)],

        [OpenOpenInterval.new(-Float::INFINITY, 1), OpenOpenInterval.new(0,3)],
        [OpenOpenInterval.new(-Float::INFINITY, 1), OpenOpenInterval.new(-1,0)],
        [OpenOpenInterval.new(-Float::INFINITY, 1), OpenOpenInterval.new(-1,1)],
        [OpenOpenInterval.new(-Float::INFINITY, 1), Point.new(0)],
        [OpenOpenInterval.new(-Float::INFINITY, 1), Point.new(1)],
        [Point.new(2), OpenOpenInterval.new(-Float::INFINITY, 1)],
        
        [Point.new(11), OpenOpenInterval.new(10, Float::INFINITY)],
        [Point.new(10), OpenOpenInterval.new(10, Float::INFINITY)],
        [OpenOpenInterval.new(10, Float::INFINITY), Point.new(11)],
        [OpenOpenInterval.new(10, Float::INFINITY), Point.new(9)],
        [OpenOpenInterval.new(10, Float::INFINITY), OpenOpenInterval.new(9,13)],
        [OpenOpenInterval.new(10, Float::INFINITY), OpenOpenInterval.new(11,13)],
        
        [OpenOpenInterval.new(1,3), Point.new(3)],
        [OpenOpenInterval.new(1,3), ClosedOpenInterval.new(3,4)],
        [OpenClosedInterval.new(1,3), ClosedOpenInterval.new(3,4)],
        [OpenClosedInterval.new(1,3), OpenOpenInterval.new(3,4)],
        [OpenOpenInterval.new(1,4), OpenOpenInterval.new(1,4)],
        [OpenOpenInterval.new(1,4), OpenOpenInterval.new(2,3)],
        [OpenOpenInterval.new(1,4), OpenOpenInterval.new(2,5)]
      ].each do |intervals|
        it("IntervalSet.new(#{intervals.map(&:to_s).join(',')}) should fail") do
          expect{ IntervalSet.new(intervals) }.to raise_error(Error)
        end
      end
    end
  end


  describe '.union' do
    # intervals = [ Empty,
    #   oo(1,3), oc(1,3), co(1,3), cc(1,3), pt(1), pt(3),
    #   oo(1,5), oc(1,5), co(1,5), cc(1,5), pt(5),
    #   oo(3,5), oc(3,5), co(3,5), cc(3,5),
    #   oo(3,4), oc(3,4), co(3,4), cc(3,4), pt(4),
    #   oo(0,5), oc(0,5), co(0,5), cc(0,5), pt(0),
    #   oo(2,5), oc(2,5), co(2,5), cc(2,5), pt(2),
    #   oo(6,7), oc(6,7), co(6,7), cc(6,7), pt(6), pt(7),
    #   oo(1,3) | oo(3,5), oo(1,3) | pt(5), oo(1,5)
    # ]

    # intervals.combination(2).each do |intervals|
    # end

    [ [Empty],
      [oo(1,3)],
      [Empty, Empty],
      [Empty, oo(1,3)],
      [oo(1,3), Empty],
      [oo(1,3), pt(3)],
      [oo(1,3), pt(4)],
      [oo(1,3), oo(5,6)],
      [oo(1,3), oo(2,6)],
      [oo(1,3), oo(3,6)],
      [oo(1,3), co(3,6)],
      [oc(1,3), oo(3,6)],
      [oc(1,3), co(3,6)],
      [oo(1,3), oo(3,6), oo(7,9)],
      [oc(1,3), co(3,6), oo(7,9)],
      [oo(1,3), pt(3), oo(3,5)],
      [oo(1,3), oo(3,6), oo(7,9), oo(15,19), oc(123,190)],
      [oo(1,3), oo(3,6), oo(7,9), oo(15,19), oc(123,190),cc(4,18)],
      [lt(0),oo(1,3), oo(3,6), oo(7,9), oo(15,19), oc(123,190),cc(4,18),ge(180)],
    ].each do |intervals|
      it "IntervalNotation::Operations.union(#{intervals.map(&:to_s).join(',')}) should be equal to #{intervals.map(&:to_s).join('|')}" do
        expect( IntervalNotation::Operations.union(intervals) ).to eq intervals.inject(&:|)
      end
    end
  end

  describe '#empty?' do
    {
      Empty => true,
      pt(1) => false,
      pt(1)|pt(3) => false,
      oo(1,5) => false,
      oo(1,5)|pt(7) => false,
      oo(1,3)|oo(3,5) => false,
      oo(1,3)|oo(3,5)|cc(6,7) => false
    }.each do |interval, answer|
      it "#{interval}.empty? should be #{answer}" do
        expect( interval.empty? ).to eq answer
      end
    end
  end

  describe '#union'  do
    {
      # Union of non-overlapping intervals
      [pt(3), pt(5)] => IntervalSet.new([Point.new(3), Point.new(5)]),
      [oo(1,3), pt(5)] => IntervalSet.new([OpenOpenInterval.new(1,3), Point.new(5)]),
      [oo(1,3), oo(3,5)] => IntervalSet.new([OpenOpenInterval.new(1,3), OpenOpenInterval.new(3,5)]),
      [oo(1,3), oo(4,5)] => IntervalSet.new([OpenOpenInterval.new(1,3), OpenOpenInterval.new(4,5)]),
      [oo(3,5), oo(1,3)] => IntervalSet.new([OpenOpenInterval.new(1,3), OpenOpenInterval.new(3,5)]),
      [oo(4,5), oo(1,3)] => IntervalSet.new([OpenOpenInterval.new(1,3), OpenOpenInterval.new(4,5)]),
      
      [oo(1,3), oo(3,5), cc(7,9)] => IntervalSet.new([OpenOpenInterval.new(1,3), OpenOpenInterval.new(3,5), ClosedClosedInterval.new(7,9)]),
      [oo(1,3), oo(3,5), oo(5,7)] => IntervalSet.new([OpenOpenInterval.new(1,3), OpenOpenInterval.new(3,5), OpenOpenInterval.new(5,7)]),
      [oo(1,3), cc(7,9), oo(3,5)] => IntervalSet.new([OpenOpenInterval.new(1,3), OpenOpenInterval.new(3,5), ClosedClosedInterval.new(7,9)]),
      [oo(1,3), oc(7,9), oo(3,5)] => IntervalSet.new([OpenOpenInterval.new(1,3), OpenOpenInterval.new(3,5), OpenClosedInterval.new(7,9)]),
      [oo(1,3), co(7,9), oo(3,5)] => IntervalSet.new([OpenOpenInterval.new(1,3), OpenOpenInterval.new(3,5), ClosedOpenInterval.new(7,9)]),
      [oo(1,3), ge(7), oo(3,5)] => IntervalSet.new([OpenOpenInterval.new(1,3), OpenOpenInterval.new(3,5), ClosedOpenInterval.new(7,Float::INFINITY)]),
      [oo(1,3), gt(7), oo(3,5),le(0)] => IntervalSet.new([OpenClosedInterval.new(-Float::INFINITY,0), OpenOpenInterval.new(1,3), OpenOpenInterval.new(3,5), OpenOpenInterval.new(7,Float::INFINITY)]),

      # union with empty interval
      [oo(1,3), Empty] => oo(1,3),
      [oo(1,3)|oo(3,5)|cc(7,9), Empty] => oo(1,3)|oo(3,5)|cc(7,9),

      # interval united with point
      [oo(1,3), pt(2)] => oo(1,3),
      [oo(1,3), pt(1)] => co(1,3),
      [co(1,3), pt(1)] => co(1,3),
      [oo(1,3), pt(0)] => pt(0)|oo(1,3),

      # union with almost the same interval
      [pt(3), pt(3)] => pt(3),
      [pt(3)|pt(5), pt(3)|pt(5)] => pt(3)|pt(5),
      [oo(1,3), oo(1,3)] => oo(1,3),
      [oo(1,3), oc(1,3)] => oc(1,3),
      [oo(1,3), co(1,3)] => co(1,3),
      [oo(1,3), cc(1,3)] => cc(1,3),

      [oo(1,3)|oo(5,7), oo(1,3)|oo(5,7)] => oo(1,3)|oo(5,7),
      [oo(1,3)|co(5,7), oo(1,3)|oo(5,7)] => oo(1,3)|co(5,7),
      [oo(1,3)|oo(5,7), oo(1,3)|co(5,7)] => oo(1,3)|co(5,7),
      [oo(1,3)|co(5,7), oo(1,3)|co(5,7)] => oo(1,3)|co(5,7),

      [pt(3)|pt(5), pt(3)|pt(7)] => pt(3)|pt(5)|pt(7),
    }.merge({ # too long hash to be one hash
      # infinite intervals
      # gt
      [gt(3), oo(1,2)] => IntervalSet.new([OpenOpenInterval.new(1, 2), OpenOpenInterval.new(3, Float::INFINITY)]),
      [gt(3), oo(1,3)] => IntervalSet.new([OpenOpenInterval.new(1, 3), OpenOpenInterval.new(3, Float::INFINITY)]),
      [gt(3), co(1,3)] => IntervalSet.new([ClosedOpenInterval.new(1, 3), OpenOpenInterval.new(3, Float::INFINITY)]),
      [gt(3), oc(1,3)] => gt(1),
      [gt(3), cc(1,3)] => ge(1),

      [gt(3), oo(2,5)] => gt(2),
      [gt(3), co(2,5)] => ge(2),
      [gt(3), co(4,5)] => gt(3),
      [gt(3), oo(4,5)] => gt(3),
      [gt(3), oo(3,5)] => gt(3),
      [gt(3), co(3,5)] => ge(3),
      [gt(3), pt(2)] => IntervalSet.new([Point.new(2), OpenOpenInterval.new(3, Float::INFINITY)]),
      [gt(3), pt(3)] => ge(3),
      [gt(3), pt(4)] => gt(3),

      # ge
      [ge(3), oo(1,2)] => IntervalSet.new([OpenOpenInterval.new(1, 2), ClosedOpenInterval.new(3, Float::INFINITY)]),
      [ge(3), oo(1,3)] => gt(1),
      [ge(3), co(1,3)] => ge(1),
      [ge(3), oc(1,3)] => gt(1),
      [ge(3), cc(1,3)] => ge(1),
      
      [ge(3), oo(2,5)] => gt(2),
      [ge(3), co(2,5)] => ge(2),
      [ge(3), co(4,5)] => ge(3),
      [ge(3), oo(4,5)] => ge(3),
      [ge(3), oo(3,5)] => ge(3),
      [ge(3), co(3,5)] => ge(3),     
      [ge(3), pt(2)] => IntervalSet.new([Point.new(2), ClosedOpenInterval.new(3, Float::INFINITY)]),
      [ge(3), pt(3)] => ge(3),
      [ge(3), pt(4)] => ge(3),

      # lt
      [lt(3), oo(4,5)] => IntervalSet.new([OpenOpenInterval.new(-Float::INFINITY, 3), OpenOpenInterval.new(4, 5)]),
      [lt(3), oo(3,5)] => IntervalSet.new([OpenOpenInterval.new(-Float::INFINITY, 3), OpenOpenInterval.new(3, 5)]),
      [lt(3), co(3,5)] => lt(5),
      [lt(3), oc(3,5)] => IntervalSet.new([OpenOpenInterval.new(-Float::INFINITY, 3), OpenClosedInterval.new(3, 5)]),
      [lt(3), cc(3,5)] => le(5),

      [lt(3), oo(1,2)] => lt(3),
      [lt(3), oo(1,3)] => lt(3),
      [lt(3), oo(1,4)] => lt(4),
      [lt(3), oc(1,2)] => lt(3),
      [lt(3), oc(1,3)] => le(3),
      [lt(3), oc(1,4)] => le(4),
      [lt(3), pt(2)] => lt(3),
      [lt(3), pt(3)] => le(3),
      [lt(3), pt(4)] => IntervalSet.new([OpenOpenInterval.new(-Float::INFINITY, 3), Point.new(4)]),

      # le
      [le(3), oo(4,5)] => IntervalSet.new([OpenClosedInterval.new(-Float::INFINITY, 3), OpenOpenInterval.new(4, 5)]),
      [le(3), oo(3,5)] => lt(5),
      [le(3), co(3,5)] => lt(5),
      [le(3), oc(3,5)] => le(5),
      [le(3), cc(3,5)] => le(5),

      [le(3), oo(1,2)] => le(3),
      [le(3), oo(1,3)] => le(3),
      [le(3), oo(1,4)] => lt(4),
      [le(3), oc(1,2)] => le(3),
      [le(3), oc(1,3)] => le(3),
      [le(3), oc(1,4)] => le(4),
      [le(3), pt(2)] => le(3),
      [le(3), pt(3)] => le(3),
      [le(3), pt(4)] => IntervalSet.new([OpenClosedInterval.new(-Float::INFINITY, 3), Point.new(4)]),

      # both infinite
      [lt(3), gt(4)] => IntervalSet.new([OpenOpenInterval.new(-Float::INFINITY, 3), OpenOpenInterval.new(4, Float::INFINITY)]),
      [lt(3), gt(3)] => IntervalSet.new([OpenOpenInterval.new(-Float::INFINITY, 3), OpenOpenInterval.new(3, Float::INFINITY)]),
      [lt(3), ge(3)] => R,
      [le(3), gt(3)] => R,
      [le(3), ge(3)] => R,
      [lt(3), gt(2)] => R,
    }).merge({ # too long hash to be one hash
      # non-adjacent
      [oo(1,3), oo(5,6)] => IntervalSet.new([OpenOpenInterval.new(1, 3), OpenOpenInterval.new(5, 6)]),
      
      # adjacent
      [oo(1,3), oo(3,6)] => IntervalSet.new([OpenOpenInterval.new(1, 3), OpenOpenInterval.new(3, 6)]),
      [oo(1,3), co(3,6)] => oo(1,6),
      [oc(1,3), oo(3,6)] => oo(1,6),
      [oc(1,3), co(3,6)] => oo(1,6),
      [oo(1,3), oo(0,1)] => IntervalSet.new([OpenOpenInterval.new(0, 1), OpenOpenInterval.new(1, 3)]),
      [oo(1,3), oc(0,1)] => oo(0,3),
      [co(1,3), oo(0,1)] => oo(0,3),
      [co(1,3), oc(0,1)] => oo(0,3),

      # overlapping
      [oo(1,3), oo(2,6)] => oo(1,6),
      [oo(1,3), co(2,6)] => oo(1,6),
      [oc(1,3), oo(2,6)] => oo(1,6),
      [oc(1,3), co(2,6)] => oo(1,6),
      [oo(1,3), oo(0,2)] => oo(0,3),
      [oo(1,3), oc(0,2)] => oo(0,3),
      [co(1,3), oo(0,2)] => oo(0,3),
      [co(1,3), oc(0,2)] => oo(0,3),

      # inside
      [oo(1,4), oo(1,4)] => oo(1,4),
      [oo(1,4), oo(1,3)] => oo(1,4),
      [oo(1,4), oo(2,4)] => oo(1,4),

      [oo(1,4), oo(2,3)] => oo(1,4),
      [oo(1,4), co(2,3)] => oo(1,4),
      [oo(1,4), oc(2,3)] => oo(1,4),
      [oo(1,4), cc(2,3)] => oo(1,4),


      # almost inside
      [oo(1,4), oc(1,4)] => oc(1,4),
      [oo(1,4), co(1,4)] => co(1,4),
      [oo(1,4), oc(1,4)] => oc(1,4),
      [oo(1,4), cc(1,4)] => cc(1,4),
      [oo(1,4), co(1,3)] => co(1,4),
      [oo(1,4), oc(2,4)] => oc(1,4),

      # outside and almost outside
      [oo(1,4), oo(0,5)] => oo(0,5),
      [oo(1,4), cc(0,5)] => cc(0,5),
      [oo(1,4), oo(0,4)] => oo(0,4),
      [oo(1,4), oo(1,5)] => oo(1,5),
      [oo(1,4), co(1,5)] => co(1,5),
      [oo(1,4), oc(0,4)] => oc(0,4),

      # union of interval set with the deleted point with another interval
      [oo(1,3)|oo(3,5), pt(2)] => oo(1,3)|oo(3,5),
      [oo(1,3)|oo(3,5), pt(3)] => oo(1,5),
      [oo(1,3)|oo(3,5), oo(1,3)] => oo(1,3)|oo(3,5),
      [oo(1,3)|oo(3,5), oo(3,5)] => oo(1,3)|oo(3,5),
      [oo(1,3)|oo(3,5), oo(1.5,2.5)] => oo(1,3)|oo(3,5),
      [oo(1,3)|oo(3,5), oo(3,6)] => oo(1,3)|oo(3,6),
      [oo(1,3)|oo(3,5), oo(4,6)] => oo(1,3)|oo(3,6),
      [oo(1,3)|oo(3,5), oo(0,3)] => oo(0,3)|oo(3,5),
      [oo(1,3)|oo(3,5), oo(0,2)] => oo(0,3)|oo(3,5),
      [oo(1,3)|oo(3,5), oo(0,6)] => oo(0,6),
      [oo(1,3)|oo(3,5), oo(1,5)] => oo(1,5),
      [oo(1,3)|oo(3,5), oo(2,4)] => oo(1,5),
      [oo(1,3)|oo(3,5), cc(2,4)] => oo(1,5),
      [oo(1,3)|oo(3,5), oc(1,3)] => oo(1,5),
      [oo(1,3)|oo(3,5), oc(2,3)] => oo(1,5),
      [oo(1,3)|oo(3,5), co(3,4)] => oo(1,5),
    }).merge({ # too long hash to be one hash
      [oo(1,3)|oo(5,7), oo(3,5)] => oo(1,3) | oo(3,5) | oo(5,7),
      [oo(1,3)|oo(5,7), co(3,5)] => oo(1,5) | oo(5,7),
      [oo(1,3)|oo(5,7), oc(3,5)] => oo(1,3) | oo(3,7),
      [oo(1,3)|oo(5,7), cc(3,5)] => oo(1,7),
      [oo(1,3)|oo(5,7)|oo(11,13), oo(3,5)|oo(7,11)] => oo(1,3)|oo(3,5)|oo(5,7)|oo(7,11)|oo(11,13),
      [oo(1,3)|cc(5,7)|oo(11,13), oo(3,5)|oo(7,11)] => oo(1,3)|oo(3,11)|oo(11,13),

      # each interval is interval set
      [oo(1,3)|oo(3,5), oo(2,3)|oo(3,7)] => oo(1,3)|oo(3,7),
      [oo(1,5), oo(2,3)|oo(3,7)] => (oo(1,7)),
      [oo(1,3)|oo(3,5), oo(2,7)] => (oo(1,7)),


      [oo(1,3)|oo(5,7), oo(3,5)] => oo(1,3)|oo(3,5)|oo(5,7),
      [oo(1,3)|oo(5,7), co(3,5)] => oo(1,5)|oo(5,7),
      [oo(1,3)|oo(5,7), cc(3,5)] => oo(1,7),
    }).each do |intervals, answer|
      it "IntervalNotation::Operations.union(#{intervals.map(&:to_s).join(',')} should equal #{answer}" do
        expect( IntervalNotation::Operations.union(intervals) ).to eq answer
      end

      it "IntervalNotation::Operations.union(#{intervals.map(&:to_s).join(',')} should equal consequent unite: #{intervals.map(&:to_s).join('|')}" do
        expect( IntervalNotation::Operations.union(intervals) ).to eq intervals.inject(&:union)
      end

      if intervals.size == 2
        interval_1, interval_2 = intervals
        it "#{interval_1} | #{interval_2} should equal #{answer}" do
          expect( interval_1.union(interval_2) ).to eq answer
        end
      end

      each_combination_of_intervals(intervals) do |chunk_1, chunk_2|
        it "#{chunk_1}.union(#{chunk_2}) should be equal to #{answer}" do
          expect( chunk_1.union(chunk_2) ).to eq answer
        end
      end
    end
  end


  describe '#intersection'  do
    {
      [oo(1,3), oo(1,3)] => oo(1,3),
      [oo(1,3), oc(1,3)] => oo(1,3),
      [oo(1,3), co(1,3)] => oo(1,3),
      [oo(1,3), cc(1,3)] => oo(1,3),

      [pt(2), pt(3)] => Empty,
      [pt(3), pt(3)] => pt(3),
      [pt(3)|pt(5), pt(3)|pt(5)] => pt(3)|pt(5),
      [pt(3)|pt(5), pt(3)|pt(7)] => pt(3),

      [oo(1,3)|oo(5,7), oo(1,3)|oo(5,7)] => oo(1,3)|oo(5,7),
      [oo(1,3)|co(5,7), oo(1,3)|oo(5,7)] => oo(1,3)|oo(5,7),
      [oo(1,3)|oo(5,7), oo(1,3)|co(5,7)] => oo(1,3)|oo(5,7),
      [oo(1,3)|co(5,7), oo(1,3)|co(5,7)] => oo(1,3)|co(5,7),

      [oo(1,3)|oo(3,5), oo(1,3)] => oo(1,3),
      [oo(1,3)|oo(3,5), oo(1,3)|oo(7,9)] => oo(1,3),
      [oo(1,3)|oo(3,5), oo(3,5)] => oo(3,5),
      [oo(1,3)|oo(3,5), oo(1,3)|oo(3,5)] => oo(1,3)|oo(3,5),

      [oo(1,3), oo(4,5)] => Empty,
      [oo(1,3), oo(3,5)] => Empty,
      [oo(1,3), co(3,5)] => Empty,
      [oc(1,3), oo(3,5)] => Empty,
      [oc(1,3), co(3,5)] => pt(3),
      
      [oo(1,3), oo(0,5)] => oo(1,3),
      [oc(1,3), oo(0,5)] => oc(1,3),
      [co(1,3), oo(0,5)] => co(1,3),
      [cc(1,3), oo(0,5)] => cc(1,3),

      [oo(1,3), oo(1,5)] => oo(1,3),
      [co(1,3), oo(1,5)] => oo(1,3),
      [oc(1,3), oo(1,5)] => oc(1,3),
      [cc(1,3), oo(1,5)] => oc(1,3),
      [co(3,5), oo(1,5)] => co(3,5),

      [oo(1,3), oo(2,5)] => oo(2,3),
      [oc(1,3), oo(2,5)] => oc(2,3),
      [oo(1,3), co(2,5)] => co(2,3),
      [oc(1,3), co(2,5)] => cc(2,3),

      [oo(1,3), pt(2)] => pt(2),
      [oo(1,3), pt(3)] => Empty,
      [oc(1,3), pt(3)] => pt(3),
      [oo(1,3), pt(4)] => Empty,
      [oc(1,3), pt(4)] => Empty,

      [oo(1,3)|oo(3,5), oo(2,3)|oo(3,7)] => oo(2,3)|oo(3,5),
      [oo(1,3)|oo(3,5), oo(2,7)] => oo(2,3)|oo(3,5),

      [oo(2,6), oo(1,3)|co(5,7)] => oo(2,3)|co(5,6),
      [oo(1,6), oo(1,3)|co(5,7)] => oo(1,3)|co(5,6),
      [oo(0,6), oo(1,3)|co(5,7)] => oo(1,3)|co(5,6),
      [oo(0,6), oo(1,3)|co(5,6)] => oo(1,3)|co(5,6),


    }.each do |intervals, answer|
      it "IntervalNotation::Operations.intersection(#{intervals.map(&:to_s).join(',')} should equal #{answer}" do
        expect( IntervalNotation::Operations.intersection(intervals) ).to eq answer
      end

      it "IntervalNotation::Operations.intersection(#{intervals.map(&:to_s).join(',')} should equal consequent unite: #{intervals.map(&:to_s).join('&')}" do
        expect( IntervalNotation::Operations.intersection(intervals) ).to eq intervals.inject(&:intersection)
      end

      if intervals.size == 2
        interval_1, interval_2 = intervals
        it "#{interval_1} & #{interval_2} should equal #{answer}" do
          expect( interval_1.intersection(interval_2) ).to eq answer
        end
      end
    end

    {
      [oo(1,3), oo(1,3), oo(1,3)] => oo(1,3),
      [oo(1,3), cc(1,3), oo(1,3)] => oo(1,3),
      [oo(1,3), cc(0,5), cc(1,3)] => oo(1,3),
      [cc(1,5), cc(3,7), cc(1,3)|cc(5,7)] => pt(3)|pt(5),
      [oo(1,5), oo(3,7), oo(1,3)|oo(5,7)] => Empty,
      [oo(1,5), oc(1,3), co(3,5)] => pt(3)
    }.each do |intervals, answer|
      it "#{intervals.map(&:to_s).join('&')} should equal #{answer}" do
        expect( IntervalNotation::Operations.intersection(intervals) ).to eq answer
      end
    end
  end

  describe '#subtract' do
    {
      [oo(1,5)|oo(6,8),(oo(1,5))] => oo(6,8),
      [oo(1,5)|oo(6,8),(oo(1,8))] => Empty,
      [oo(1,5)|oo(6,8),(cc(1,5))] => oo(6,8),
      [oo(1,5),cc(2,3)] => oo(1,2)|oo(3,5),
      [oo(1,5),oo(2,3)] => oc(1,2)|co(3,5),
      [oo(1,5),oo(1,3)] => co(3,5),
      [oo(1,5),pt(0)] => oo(1,5),
      [oo(1,5),pt(1)] => oo(1,5),
      [co(1,5),pt(1)] => oo(1,5),
      [oo(1,5),pt(3)] => oo(1,3)|oo(3,5),
      [cc(1,5),oo(1,3)] => pt(1)|cc(3,5),
      [cc(1,5),co(1,3)] => cc(3,5),
      [oo(1,5),cc(1,3)] => oo(3,5),
      [oo(1,5),oo(0,3)] => co(3,5),
      [oo(1,5),oo(0,2)|oo(3,4)] => cc(2,3)|co(4,5),
      [R,oo(1,5)] => le(1)|ge(5),
      [R,oc(1,5)] => le(1)|gt(5),
      [R,co(1,5)] => lt(1)|ge(5),
      [R,pt(3)] => lt(3)|gt(3),
      [R,Empty] => R,
      [R,R] => Empty,
      [oo(1,5),R] => Empty,
      [pt(3),R] => Empty,
      [oo(1,3)|pt(5)|cc(7,10),R] => Empty,
      [Empty,R] => Empty,
      [Empty,pt(3)] => Empty,
      [Empty,oo(1,3)] => Empty,
    }.each do |(interval_1, interval_2), answer|
      it "#{interval_1} - #{interval_2} should equal #{answer}" do
        expect( interval_1.subtract(interval_2) ).to eq answer
      end
    end
  end

  describe '#symmetric_difference' do
    {
      [oo(1,3),oo(1,3)] => Empty,
      [cc(1,3),cc(1,3)] => Empty,
      [cc(1,3),pt(2)] => co(1,2)|oc(2,3),
      [cc(1,3),oo(1,3)] => pt(1)|pt(3),
      [oo(1,4),oo(2,3)] => oc(1,2)|co(3,4),
      [oo(1,4),cc(2,3)] => oo(1,2)|oo(3,4),
      [oo(1,4),Empty] => oo(1,4),
      [oo(1,4),R] => le(1)|ge(4),
    }.each do |(interval_1, interval_2), answer|
      it "#{interval_1} ^ #{interval_2} should equal #{answer}" do
        expect( interval_1.symmetric_difference(interval_2) ).to eq answer
      end
      it "#{interval_2} ^ #{interval_1} should equal #{answer}" do
        expect( interval_2.symmetric_difference(interval_1) ).to eq answer
      end
      it "#{interval_1} ^ #{answer} should equal #{interval_2}" do
        expect( interval_1.symmetric_difference(answer) ).to eq interval_2
      end
      it "#{interval_2} ^ #{answer} should equal #{interval_1}" do
        expect( interval_2.symmetric_difference(answer) ).to eq interval_1
      end
    end
  end

  describe '#complement' do
    {
      oo(1,3)|cc(5,6) => le(1)|co(3,5)|gt(6),
      oo(1,5) => le(1)|ge(5),
      oc(1,5) => le(1)|gt(5),
      co(1,5) => lt(1)|ge(5),
      pt(3) => lt(3)|gt(3),
      Empty => R,
      R => Empty,
    }.each do |interval, answer|
      it "#{interval}.complement should equal #{answer}" do
        expect( interval.complement ).to eq answer
      end
    end
  end

  describe '#include_position?' do
    {
      [oo(1,3), -100] => false,
      [oo(1,3), 0] => false,
      [oo(1,3), 1] => false,
      [oo(1,3), 2] => true,
      [oo(1,3), 3] => false,
      [oo(1,3), 4] => false,
      [oo(1,3), 100] => false,

      [co(1,3), -100] => false,
      [co(1,3), 0] => false,
      [co(1,3), 1] => true,
      [co(1,3), 2] => true,
      [co(1,3), 3] => false,
      [co(1,3), 4] => false,
      [co(1,3), 100] => false,

      [oc(1,3), -100] => false,
      [oc(1,3), 0] => false,
      [oc(1,3), 1] => false,
      [oc(1,3), 2] => true,
      [oc(1,3), 3] => true,
      [oc(1,3), 4] => false,
      [oc(1,3), 100] => false,

      [cc(1,3), -100] => false,
      [cc(1,3), 0] => false,
      [cc(1,3), 1] => true,
      [cc(1,3), 2] => true,
      [cc(1,3), 3] => true,
      [cc(1,3), 4] => false,
      [cc(1,3), 100] => false,

      [cc(0,2)|pt(4)|pt(6)|cc(8,10), -1] => false,
      [cc(0,2)|pt(4)|pt(6)|cc(8,10), 0] => true,
      [cc(0,2)|pt(4)|pt(6)|cc(8,10), 1] => true,
      [cc(0,2)|pt(4)|pt(6)|cc(8,10), 2] => true,
      [cc(0,2)|pt(4)|pt(6)|cc(8,10), 3] => false,
      [cc(0,2)|pt(4)|pt(6)|cc(8,10), 4] => true,
      [cc(0,2)|pt(4)|pt(6)|cc(8,10), 5] => false,
      [cc(0,2)|pt(4)|pt(6)|cc(8,10), 6] => true,
      [cc(0,2)|pt(4)|pt(6)|cc(8,10), 7] => false,
      [cc(0,2)|pt(4)|pt(6)|cc(8,10), 8] => true,
      [cc(0,2)|pt(4)|pt(6)|cc(8,10), 9] => true,
      [cc(0,2)|pt(4)|pt(6)|cc(8,10), 10] => true,
      [cc(0,2)|pt(4)|pt(6)|cc(8,10), 11] => false,

      [lt(-10)|cc(1,3)|ge(10), -1000] => true,
      [lt(-10)|cc(1,3)|ge(10), -11] => true,
      [lt(-10)|cc(1,3)|ge(10), -10] => false,
      [lt(-10)|cc(1,3)|ge(10), -9] => false,
      [lt(-10)|cc(1,3)|ge(10), 0] => false,
      [lt(-10)|cc(1,3)|ge(10), 1] => true,
      [lt(-10)|cc(1,3)|ge(10), 2] => true,
      [lt(-10)|cc(1,3)|ge(10), 3] => true,
      [lt(-10)|cc(1,3)|ge(10), 4] => false,
      [lt(-10)|cc(1,3)|ge(10), 9] => false,
      [lt(-10)|cc(1,3)|ge(10), 10] => true,
      [lt(-10)|cc(1,3)|ge(10), 11] => true,
      [lt(-10)|cc(1,3)|ge(10), 1000] => true,
    }.each do |(interval, point), answer|
      if answer
        it "#{interval}.include_position?(#{point}) should be truthy" do
          expect( interval.include_position?(point) ).to be_truthy
        end
      else
        it "#{interval}.include_position?(#{point}) should be falsy" do
          expect( interval.include_position?(point) ).to be_falsy
        end
      end
    end
  end

  describe '#contain? / contained_by?' do 
    {
      [oo(1,3), oo(1,2)] => true,
      [oo(1,3), oo(1.5,2.5)] => true,
      [oo(1,3), cc(1.5,2.5)] => true,
      [oo(1,3), oo(2,3)] => true,
      [oo(1,3), oo(1,3)] => true,
      [cc(1,3), oo(1,3)] => true,
      [cc(1,3), cc(1,3)] => true,
      [oo(1,3), cc(1,3)] => false,
      [oo(1,3), co(1,3)] => false,
      [oo(1,3)|pt(4)|cc(8,10), oo(1,3)|oc(9,10) ] => true,
      [oo(1,3)|pt(4)|cc(8,10), oo(1,3)|pt(4) ] => true,
      [oo(1,3)|pt(4)|cc(8,10), oo(1,3)|pt(5) ] => false,
      [oo(1,3)|pt(4)|cc(8,10), oo(1,3)|pt(8) ] => true,
      [lt(10), oo(1,3)] => true,
      [lt(10), oo(10,11)] => false,
      [le(10), oo(10,11)] => false,
    }.each do |(interval_1, interval_2), answer|
      if answer
        it "#{interval_1}.contain?(#{interval_2}) should be truthy" do
          expect( interval_1.contain?(interval_2) ).to be_truthy
        end
        it "#{interval_2}.contained_by?(#{interval_1}) should be truthy" do
          expect( interval_2.contained_by?(interval_1) ).to be_truthy
        end
      else
        it "#{interval_1}.contain?(#{interval_2}) should be falsy" do
          expect( interval_1.contain?(interval_2) ).to be_falsy
        end
        it "#{interval_2}.contained_by?(#{interval_1}) should be falsy" do
          expect( interval_2.contained_by?(interval_1) ).to be_falsy
        end
      end
    end
  end

  describe '#intersect?' do 
    {
      [oo(1,3), oo(1,2)] => true,
      [oo(1,3), oo(1,3)] => true,
      [oo(1,3), cc(1.5,2.5)] => true,
      
      [oo(1,3), oo(3,4)] => false,
      [oc(1,3), oo(3,4)] => false,
      [oo(1,3), co(3,4)] => false,
      [oc(1,3), co(3,4)] => true,

      [oo(1,3), oo(4,5)] => false,
      [cc(1,3), cc(4,5)] => false,
      [cc(1,3), pt(2)|cc(4,5)] => true,
      [co(1,3), pt(2)|cc(4,5)] => true,
      [cc(1,3), pt(3)|cc(4,5)] => true,
      [co(1,3), pt(3)|cc(4,5)] => false,
      [cc(1,3), cc(4,5)|pt(6)] => false,

      [lt(10), oo(1,3)] => true,
      [lt(10), oo(11,12)] => false,
      [lt(10), oo(10,11)] => false,
      [le(10), co(10,11)] => true,
      [le(10), le(9)] => true,
      [le(10), le(11)] => true,
      [le(10), ge(11)] => false,
      [le(10), ge(10)] => true,
      [le(10), gt(10)] => false,
      [le(10), gt(11)] => false,
    }.each do |(interval_1, interval_2), answer|
      if answer
        it "#{interval_1}.intersect?(#{interval_2}) should be truthy" do
          expect( interval_1.intersect?(interval_2) ).to be_truthy
        end
      else
        it "#{interval_1}.intersect?(#{interval_2}) should be falsy" do
          expect( interval_1.intersect?(interval_2) ).to be_falsy
        end
      end
    end
  end
end
