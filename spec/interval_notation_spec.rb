require_relative 'spec_helper'

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

  describe 'closed_closed helper' do
    specify 'closed_closed(x,x) returns point(x)' do
      expect(cc(3,3)).to eq(pt(3))
      expect(IntervalNotation::Syntax::Long.closed_closed(3,3)).to eq(IntervalNotation::Syntax::Long.point(3))
    end
  end

  describe '.to_s' do
    {
      Empty => '∅',
      R => '(-∞;+∞)',
      oo(1,3) => '(1;3)',
      oc(1,3) => '(1;3]',
      co(1,3) => '[1;3)',
      cc(1,3) => '[1;3]',
      lt(3) => '(-∞;3)',
      le(3) => '(-∞;3]',
      gt(3) => '(3;+∞)',
      ge(3) => '[3;+∞)',
      pt(2) => '{2}',
      oo(1,3) | cc(4,5) => '(1;3)∪[4;5]',
      oo(1,3) | pt(4) => '(1;3)∪{4}',
      pt(-1) | oo(1,3) | pt(4) => '{-1}∪(1;3)∪{4}',
      pt(1) | pt(4) => '{1}∪{4}',
    }.each do |interval, str|
      it "String representation #{interval.to_s} should eq #{str}" do
        expect(interval.to_s).to eq str
      end
      it "Interval created by string representation #{interval.to_s} is the same as a source interval" do
        expect(IntervalNotation::IntervalSet.from_string(interval.to_s)).to eq interval
      end
    end
  end

  describe 'IntervalNotation::IntervalSet.from_string' do
    {
      '∅' => Empty,
      'Empty' => Empty,
      'empty' => Empty,
      '' => Empty,
      'R' => R,
      '3' => pt(3),
      '-3' => pt(-3),
      '{3}' => pt(3),
      '{3,5}' => pt(3) | pt(5),
      '{3;5}' => pt(3) | pt(5),
      '{3}u{5}' => pt(3) | pt(5),
      '{3}U{5}' => pt(3) | pt(5),
      '{3}∪{5}' => pt(3) | pt(5),
      '(0,1)' => oo(0,1),
      '(0,1]' => oc(0,1),
      '[0,1)' => co(0,1),
      '[0,1]' => cc(0,1),
      '(0,1)U(2,5.5)' => oo(0,1) | oo(2,5.5),
      '(0;1)U(2;5.5)' => oo(0,1) | oo(2,5.5),
      '(- 2; 5.5)' => oo(-2, 5.5),
      '(-∞; ∞)' => R,
      '(-∞; 1)' => lt(1),
      '(-inf; 1)' => lt(1),
      '(-infty; 1)' => lt(1),
      '(-\infty; 1)' => lt(1),
      '(-infinity; 1)' => lt(1),
      '(1;∞)' => gt(1),
      '(1;inf)' => gt(1),
      '(1;infty)' => gt(1),
      '(1;\infty)' => gt(1),
      '(1;infinity)' => gt(1),
      '(1;+∞)' => gt(1),
      '[1;+∞)' => ge(1),
      '[1;+inf)' => ge(1),
      '[1;+infty)' => ge(1),
      '[1;+\infty)' => ge(1),
      '[1;+infinity)' => ge(1),
    }.each do |str, interval|
      it "IntervalNotation::IntervalSet.from_string from string #{str} should eq #{interval}" do
        expect(IntervalNotation::IntervalSet.from_string(str)).to eq interval
      end
    end
  end

  describe '.union' do
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



  describe '#contiguous?' do
    it 'Empty interval is treated as contiguous' do
      expect(Empty).to be_contiguous
    end

    it 'Single component intervals are treated as contiguous' do
      expect(R).to be_contiguous
      expect(oo(1,3)).to be_contiguous
      expect(cc(1,3)).to be_contiguous
      expect(lt(3)).to be_contiguous
      expect(ge(3)).to be_contiguous
      expect(pt(3)).to be_contiguous
    end

    it 'Several components intervals are treated as contiguous' do
      expect(oo(1,3)|oo(3,5)).not_to be_contiguous
      expect(oo(1,3)|oo(3,5)|oo(10,15)).not_to be_contiguous
      expect(oo(1,3)|pt(5)).not_to be_contiguous
      expect(cc(1,3)|pt(5)).not_to be_contiguous
      expect(cc(1,3)|ge(5)).not_to be_contiguous
      expect(pt(3)|ge(5)).not_to be_contiguous
      expect(lt(3)|ge(5)).not_to be_contiguous
      expect(pt(3)|pt(5)).not_to be_contiguous
    end
  end

  describe '#num_connected_components' do
    {
      oo(1,3) => 1,
      oc(1,3) => 1,
      co(1,3) => 1,
      cc(1,3) => 1,
      oo(1,3) | oo(3,6) => 2,
      oo(1,3) | oo(5,8) => 2,
      oo(1,3) | oo(3,6) | cc(10,15) => 3,
      oo(1,3) | pt(4) | oo(5,8) => 3,
      Empty => 0,
      pt(3) => 1,
      pt(3) | pt(5) => 2,
      lt(3) => 1,
      le(3) => 1,
      gt(3) => 1,
      ge(3) => 1,
      R => 1,
    }.each do |interval, answer|
      it "#{interval}.num_connected_components should equal #{answer}" do
        expect(interval.num_connected_components).to eq answer
      end
    end
  end

  describe '#total_length' do
    {
      oo(1,3) => 2,
      oc(1,3) => 2,
      co(1,3) => 2,
      cc(1,3) => 2,
      oo(1,3) | oo(3,6) => 5,
      oo(1,3) | oo(5,8) => 5,
      oo(1,3) | pt(4) | oo(5,8) => 5,
      Empty => 0,
      pt(3) => 0,
      pt(3) | pt(5) => 0,
      lt(3) => Float::INFINITY,
      le(3) => Float::INFINITY,
      gt(3) => Float::INFINITY,
      ge(3) => Float::INFINITY,
      R => Float::INFINITY,
    }.each do |interval, answer|
      it "#{interval}.total_length should equal #{answer}" do
        expect(interval.total_length).to eq answer
      end
    end
  end

  describe '#covering_interval' do
    {
      Empty => Empty,
      oo(1,3) => oo(1,3),
      oc(1,3) => oc(1,3),
      co(1,3) => co(1,3),
      cc(1,3) => cc(1,3),
      pt(3) => pt(3),
      lt(3) => lt(3),
      le(3) => le(3),
      gt(3) => gt(3),
      ge(3) => ge(3),
      R => R,
      pt(3) | pt(4) => cc(3,4),
      oo(1,3) | pt(4) => oc(1,4),
      pt(0) | oo(1,3) | pt(4) => cc(0,4),
      pt(0) | oc(1,3) => cc(0,3),
      oo(1,3) | oo(3,6) => oo(1,6),
      oo(1,3) | oc(3,6) => oc(1,6),
      oo(1,3) | oc(5,8) => oc(1,8),
      co(1,3) | oc(5,8) => cc(1,8),
      cc(1,3) | cc(5,8) => cc(1,8),
      oo(1,3) | oo(3,6) | cc(10,15) => oc(1,15),
      oo(1,3) | pt(4) | oo(5,8) => oo(1,8),
    }.each do |interval, answer|
      it "#{interval}.covering_interval should equal #{answer}" do
        expect(interval.covering_interval).to eq answer
      end
    end
  end

  describe '#closure' do
    {
      Empty => Empty,
      oo(1,3) => cc(1,3),
      oc(1,3) => cc(1,3),
      co(1,3) => cc(1,3),
      cc(1,3) => cc(1,3),
      pt(3) => pt(3),
      lt(3) => le(3),
      le(3) => le(3),
      gt(3) => ge(3),
      ge(3) => ge(3),
      lt(3) | gt(3) => R,
      lt(3) | gt(4) => le(3) | ge(4),
      oo(1,3) | oo(4,5) => cc(1,3) | cc(4,5),
      oc(1,3) | co(4,5) => cc(1,3) | cc(4,5),
      R => R,
      oo(1,3) | pt(4) => cc(1,3) | pt(4),
      pt(3) | pt(4) => pt(3) | pt(4),
      oo(1,3) | oo(3,4) => cc(1,4),
      co(1,3) | oc(3,4) => cc(1,4),
      oo(1,3) | oo(3,6) | cc(10,15) => cc(1,6) | cc(10,15),
      oo(1,3) | oo(3,6) | gt(10) => cc(1,6) | ge(10),
      oo(1,3) | pt(4) | oo(5,8) => cc(1,3) | pt(4) | cc(5,8),
    }.each do |interval, answer|
      it "#{interval}.covering_interval should equal #{answer}" do
        expect(interval.closure).to eq answer
      end
    end

    describe '#connected_components' do
      {
        Empty => [],
        oo(1,3) => [oo(1,3)],
        cc(5,6) => [cc(5,6)],
        pt(4) => [pt(4)],
        oo(1,3) | pt(4) => [oo(1,3), pt(4)],
        oo(1,3) | cc(5,6) => [oo(1,3), cc(5,6)],
        oo(1,3) | pt(4) | cc(5,6) => [oo(1,3), pt(4), cc(5,6)],
      }.each do |interval, answer|
        it "#{interval}.connected_components should equal #{answer}" do
          expect(interval.connected_components).to eq answer
        end
      end
    end

    describe '#interval_covering_point' do
      {
        [Empty, 2] => nil,
        [oo(1,3), 2] => OpenOpenInterval.new(1,3),
        [cc(1,3), 2] => ClosedClosedInterval.new(1,3),
        [oo(1,3), 4] => nil,
        [oo(1,3), 3] => nil,
        [oo(1,3), 1] => nil,
        [cc(1,3), 1] => ClosedClosedInterval.new(1,3),
        [cc(1,3), 3] => ClosedClosedInterval.new(1,3),
        [pt(4), 5] => nil,
        [pt(4), 4] => Point.new(4),
        [oo(1,3) | pt(4), 4] => Point.new(4),
        [oo(1,3) | oo(5,6), 4] => nil,
        [oo(1,3) | oo(5,6), 2] => OpenOpenInterval.new(1,3),
        [oo(1,3) | oo(5,6), 5.5] => OpenOpenInterval.new(5,6),
        [oo(1,3) | pt(4) | oo(5,6), 4] => Point.new(4),
        [oo(1,3) | pt(4) | oo(5,6), 2] => OpenOpenInterval.new(1,3),
        [oo(1,3) | pt(4) | oo(5,6), 5.5] => OpenOpenInterval.new(5,6),
      }.each do |(interval, point), answer|
        it "#{interval}.interval_covering_point(#{point}) should equal #{answer}" do
          expect(interval.interval_covering_point(point)).to eq answer
        end
      end
    end
  end
end
