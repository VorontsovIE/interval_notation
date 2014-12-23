require 'interval_notation'

include IntervalNotation

describe IntervalNotation do

  describe OpenOpenInterval do
    describe '.new' do
      it 'OpenOpenInterval.new with from < to should not raise' do
        expect{ OpenOpenInterval.new(1, 3) }.not_to raise_error
      end
      
      it 'OpenOpenInterval.new with to equal to +inf should not raise' do
        expect{ OpenOpenInterval.new(1, Float::INFINITY) }.not_to raise_error
      end
      
      it 'OpenOpenInterval.new with from equal to -inf should not raise' do
        expect{ OpenOpenInterval.new(-Float::INFINITY, 1) }.not_to raise_error
      end
      
      it 'OpenOpenInterval.new with to and from, both equal to -inf/+inf should not raise' do
        expect{ OpenOpenInterval.new(-Float::INFINITY, Float::INFINITY) }.not_to raise_error
      end


      it 'OpenOpenInterval.new with from == to should raise' do
        expect{ OpenOpenInterval.new(1, 1) }.to raise_error Error
      end

      it 'OpenOpenInterval.new with from > to should raise' do
        expect{ OpenOpenInterval.new(3, 1) }.to raise_error Error
      end
      
      it 'OpenOpenInterval.new with from > to, and to is -inf should raise' do
        expect{ OpenOpenInterval.new(1, -Float::INFINITY) }.to raise_error Error
      end
      
      it 'OpenOpenInterval.new with from > to, and from is inf should raise' do
        expect{ OpenOpenInterval.new(Float::INFINITY, 1) }.to raise_error Error
      end
      
      it 'OpenOpenInterval.new with from > to, and to and from are both inf should raise' do
        expect{ OpenOpenInterval.new(Float::INFINITY, -Float::INFINITY) }.to raise_error Error
        expect{ OpenOpenInterval.new(Float::INFINITY, Float::INFINITY) }.to raise_error Error
        expect{ OpenOpenInterval.new(-Float::INFINITY, -Float::INFINITY) }.to raise_error Error
      end
    end
  end


  describe OpenClosedInterval do
    describe '.new' do
      it 'OpenClosedInterval.new with from < to should not raise' do
        expect{ OpenClosedInterval.new(1, 3) }.not_to raise_error
      end

      it 'OpenClosedInterval.new with from equal to -inf should not raise' do
        expect{ OpenClosedInterval.new(-Float::INFINITY, 3) }.not_to raise_error
      end


      it 'OpenClosedInterval.new with from == to should raise' do
        expect{ OpenClosedInterval.new(1, 1) }.to raise_error Error
      end

      it 'OpenClosedInterval.new with from > to should raise' do
        expect{ OpenClosedInterval.new(3, 1) }.to raise_error Error
      end
      
      it 'OpenClosedInterval.new with from > to, and to is -inf should raise' do
        expect{ OpenClosedInterval.new(1, -Float::INFINITY) }.to raise_error Error
      end
      
      it 'OpenClosedInterval.new with from > to, and from is inf should raise' do
        expect{ OpenClosedInterval.new(Float::INFINITY, 1) }.to raise_error Error
      end
      
      it 'OpenClosedInterval.new with from > to, and to and from are both inf should raise' do
        expect{ OpenClosedInterval.new(Float::INFINITY, -Float::INFINITY) }.to raise_error Error
        expect{ OpenClosedInterval.new(Float::INFINITY, Float::INFINITY) }.to raise_error Error
        expect{ OpenClosedInterval.new(-Float::INFINITY, -Float::INFINITY) }.to raise_error Error
      end
      
      it 'OpenClosedInterval.new with to equal to +inf should raise' do
        expect{ OpenClosedInterval.new(1, Float::INFINITY) }.to raise_error Error
      end
      
      it 'OpenClosedInterval.new with to and from, both equal to -inf/+inf should raise' do
        expect{ OpenClosedInterval.new(-Float::INFINITY, Float::INFINITY) }.to raise_error Error
      end
    end
  end


  describe ClosedOpenInterval do
    describe '.new' do
      it 'ClosedOpenInterval.new with from < to should not raise' do
        expect{ ClosedOpenInterval.new(1, 3) }.not_to raise_error
      end
      
      it 'ClosedOpenInterval.new with to equal to +inf should not raise' do
        expect{ ClosedOpenInterval.new(1, Float::INFINITY) }.not_to raise_error
      end
      

      it 'ClosedOpenInterval.new with from equal to -inf should raise' do
        expect{ ClosedOpenInterval.new(-Float::INFINITY, 1) }.to raise_error Error
      end
      
      it 'ClosedOpenInterval.new with to and from, both equal to -inf/+inf should raise' do
        expect{ ClosedOpenInterval.new(-Float::INFINITY, Float::INFINITY) }.to raise_error Error
      end

      it 'ClosedOpenInterval.new with from == to should raise' do
        expect{ ClosedOpenInterval.new(1, 1) }.to raise_error Error
      end

      it 'ClosedOpenInterval.new with from > to should raise' do
        expect{ ClosedOpenInterval.new(3, 1) }.to raise_error Error
      end
      
      it 'ClosedOpenInterval.new with from > to, and to is -inf should raise' do
        expect{ ClosedOpenInterval.new(1, -Float::INFINITY) }.to raise_error Error
      end
      
      it 'ClosedOpenInterval.new with from > to, and from is inf should raise' do
        expect{ ClosedOpenInterval.new(Float::INFINITY, 1) }.to raise_error Error
      end
      
      it 'ClosedOpenInterval.new with from > to, and to and from are both inf should raise' do
        expect{ ClosedOpenInterval.new(Float::INFINITY, -Float::INFINITY) }.to raise_error Error
        expect{ ClosedOpenInterval.new(Float::INFINITY, Float::INFINITY) }.to raise_error Error
        expect{ ClosedOpenInterval.new(-Float::INFINITY, -Float::INFINITY) }.to raise_error Error
      end
    end
  end


  describe ClosedClosedInterval do
    describe '.new' do
      it 'ClosedClosedInterval.new with from < to should not raise' do
        expect{ ClosedClosedInterval.new(1, 3) }.not_to raise_error
      end


      it 'ClosedClosedInterval.new with from equal to -inf should raise' do
        expect{ ClosedClosedInterval.new(-Float::INFINITY, 3) }.to raise_error Error
      end

      it 'ClosedClosedInterval.new with from == to should raise' do
        expect{ ClosedClosedInterval.new(1, 1) }.to raise_error Error
      end

      it 'ClosedClosedInterval.new with from > to should raise' do
        expect{ ClosedClosedInterval.new(3, 1) }.to raise_error Error
      end
      
      it 'ClosedClosedInterval.new with from > to, and to is -inf should raise' do
        expect{ ClosedClosedInterval.new(1, -Float::INFINITY) }.to raise_error Error
      end
      
      it 'ClosedClosedInterval.new with from > to, and from is inf should raise' do
        expect{ ClosedClosedInterval.new(Float::INFINITY, 1) }.to raise_error Error
      end
      
      it 'ClosedClosedInterval.new with from > to, and to and from are both inf should raise' do
        expect{ ClosedClosedInterval.new(Float::INFINITY, -Float::INFINITY) }.to raise_error Error
        expect{ ClosedClosedInterval.new(Float::INFINITY, Float::INFINITY) }.to raise_error Error
        expect{ ClosedClosedInterval.new(-Float::INFINITY, -Float::INFINITY) }.to raise_error Error
      end
      
      it 'ClosedClosedInterval.new with to equal to +inf should raise' do
        expect{ ClosedClosedInterval.new(1, Float::INFINITY) }.to raise_error Error
      end
      
      it 'ClosedClosedInterval.new with to and from, both equal to -inf/+inf should raise' do
        expect{ ClosedClosedInterval.new(-Float::INFINITY, Float::INFINITY) }.to raise_error Error
      end
    end
  end

  describe Point do
    it 'should not raise if finite' do
      expect{ Point.new(3) }.not_to raise_error      
    end
    it 'should raise if infinite' do
      expect{ Point.new(-Float::INFINITY) }.to raise_error      
      expect{ Point.new(Float::INFINITY) }.to raise_error      
    end
  end


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
      it "IntervalNotation.union(#{intervals.map(&:to_s).join(',')}) should be equal to #{intervals.map(&:to_s).join('|')}" do
        expect( IntervalNotation.union(intervals) ).to eq intervals.inject(&:|)
      end
    end
  end

  describe '#empty?' do
    {
      Empty => true,
      oo(1,5) => false,
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
      [oo(1,3)|oo(3,5), oo(2,3)|oo(3,7)] => oo(1,3)|oo(3,7),
      [oo(1,5), oo(2,3)|oo(3,7)] => (oo(1,7)),
      [oo(1,3)|oo(3,5), oo(2,7)] => (oo(1,7)),
        
      [oo(1,3), Empty] => (oo(1,3)),
      [oo(1,3), oo(5,6)] => oo(1,3)|oo(5,6),
      [oo(1,3), oo(3,6)] => oo(1,3)|oo(3,6),
      [oo(1,3), oo(2,6)] => oo(1,6),
      [oc(1,3), co(5,6)] => oc(1,3)|co(5,6),
      [cc(1,3), oc(5,6)] => cc(1,3)|oc(5,6),
      [oo(1,3), co(3,6)] => oo(1,6),
      [oo(1,3), oo(2,3)] => oo(1,3),
      [oo(1,3), oc(2,3)] => oc(1,3),
      [oc(1,3), oo(2,3)] => oc(1,3),
      [oo(1,3), oo(1,3)] => oo(1,3),
      [oo(1,3), oo(0,4)] => oo(0,4),
      [oo(0,4), oo(1,3)] => oo(0,4),
      [oo(1,3)|oo(3,5), pt(3)] => oo(1,5),

      [oo(1,3), pt(2)] => oo(1,3),
      [oo(1,3), pt(1)] => co(1,3),
      [co(1,3), pt(1)] => co(1,3),
      [oo(1,3), pt(0)] => pt(0)|oo(1,3),

      [oo(1,3)|oo(5,7), oo(3,5)] => oo(1,3)|oo(3,5)|oo(5,7),
      [oo(1,3)|oo(5,7), co(3,5)] => oo(1,5)|oo(5,7),
      [oo(1,3)|oo(5,7), cc(3,5)] => oo(1,7),
      [lt(3), gt(2)] => R,
      [lt(3), gt(4)] => lt(3) | gt(4),
      [lt(3), ge(3)] => R,
    }.each do |(interval_1, interval_2), answer|
      it "#{interval_1} | #{interval_2} should equal #{answer}" do
        expect( interval_1.union(interval_2) ).to eq answer
        expect( IntervalNotation.union([interval_1, interval_2]) ).to eq answer
      end
    end
  end


  describe '#intersection'  do
    {
      [oo(1,3)|oo(3,5), oo(2,3)|oo(3,7)] => oo(2,3)|oo(3,5),
      [oo(1,3)|oo(3,5), oo(2,7)] => oo(2,3)|oo(3,5),

      [oo(1,3), oo(2,5)] => oo(2,3),
      [oo(1,3), oo(4,5)] => Empty,

      [oo(1,3), oo(3,5)] => Empty,
      [oo(1,3), co(3,5)] => Empty,
      [oc(1,3), oo(3,5)] => Empty,
      [oc(1,3), co(3,5)] => pt(3),

      [oo(2,6), oo(1,3)|co(5,7)] => oo(2,3)|co(5,6),
      [oo(1,6), oo(1,3)|co(5,7)] => oo(1,3)|co(5,6),
      [oo(0,6), oo(1,3)|co(5,7)] => oo(1,3)|co(5,6),
      [oo(0,6), oo(1,3)|co(5,6)] => oo(1,3)|co(5,6),
        
      [oo(1,3), pt(2)] => pt(2),
      [oo(1,3), pt(1)] => Empty,
      [co(1,3), pt(0)] => Empty,
      [co(1,3), pt(1)] => pt(1),

    }.each do |(interval_1, interval_2), answer|
      it "#{interval_1} & #{interval_2} should equal #{answer}" do
        expect( interval_1.intersection(interval_2) ).to eq answer
        expect( IntervalNotation.intersection([interval_1, interval_2]) ).to eq answer
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
      [oo(1,5),R] => Empty,
    }.each do |(interval_1, interval_2), answer|
      it "#{interval_1} - #{interval_2} should equal #{answer}" do
        expect( interval_1.subtract(interval_2) ).to eq answer
      end
    end
  end

  describe '#include_position?' do
    {
      [oo(1,3), 2] => true,
      [oo(1,3), 3] => false,
      [oo(1,3), 1] => false,
      [oo(1,3), 4] => false,
      [oo(1,3), 0] => false,
      [oo(1,3), 100] => false,
      [oo(1,3), -100] => false,
      
      [co(1,3), 2] => true,
      [co(1,3), 1] => true,
      [co(1,3), 3] => false,
      [co(1,3), 4] => false,
      [co(1,3), 0] => false,
      
      [oc(1,3), 2] => true,
      [oc(1,3), 1] => false,
      [oc(1,3), 3] => true,
      [oc(1,3), 4] => false,
      [oc(1,3), 0] => false,
      
      [cc(1,3), 2] => true,
      [cc(1,3), 1] => true,
      [cc(1,3), 3] => true,
      [cc(1,3), 4] => false,
      [cc(1,3), 0] => false,

      [lt(-10) | cc(1,3) | ge(10), 2] => true,
      [lt(-10) | cc(1,3) | ge(10), 1] => true,
      [lt(-10) | cc(1,3) | ge(10), 3] => true,
      [lt(-10) | cc(1,3) | ge(10), 4] => false,
      [lt(-10) | cc(1,3) | ge(10), 0] => false,
      [lt(-10) | cc(1,3) | ge(10), -10] => false,
      [lt(-10) | cc(1,3) | ge(10), -11] => true,
      [lt(-10) | cc(1,3) | ge(10), -1000] => true,
      [lt(-10) | cc(1,3) | ge(10), 10] => true,
      [lt(-10) | cc(1,3) | ge(10), 10] => true,
      [lt(-10) | cc(1,3) | ge(10), 1000] => true,
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
end
