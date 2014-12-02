require 'interval_notation'

include IntervalNotation

describe IntervalNotation::IntervalSet do
  let(:helpers) { IntervalNotation::IntervalSet::Helpers }

  describe '#consequent_intervals_not_overlap?' do
    it{ expect(helpers.consequent_intervals_not_overlap?(OpenOpenInterval.new(1,5), OpenOpenInterval.new(5,7))).to be_truthy }
    it{ expect(helpers.consequent_intervals_not_overlap?(OpenClosedInterval.new(1,5), OpenOpenInterval.new(5,7))).to be_truthy }
    it{ expect(helpers.consequent_intervals_not_overlap?(OpenOpenInterval.new(1,5), ClosedOpenInterval.new(5,7))).to be_truthy }
    it{ expect(helpers.consequent_intervals_not_overlap?(OpenClosedInterval.new(1,5), ClosedOpenInterval.new(5,7))).to be_falsy }
    
    it{ expect(helpers.consequent_intervals_not_overlap?(OpenClosedInterval.new(1,5), ClosedClosedInterval.new(6,7))).to be_truthy }
    it{ expect(helpers.consequent_intervals_not_overlap?(OpenClosedInterval.new(1,5), ClosedClosedInterval.new(4,7))).to be_falsy }
    it{ expect(helpers.consequent_intervals_not_overlap?(OpenClosedInterval.new(1,5), ClosedClosedInterval.new(2,3))).to be_falsy }
    
    it{ expect(helpers.consequent_intervals_not_overlap?(OpenOpenInterval.new(1,5), Point.new(5))).to be_truthy }
    it{ expect(helpers.consequent_intervals_not_overlap?(OpenOpenInterval.new(1,4), Point.new(5))).to be_truthy }
    it{ expect(helpers.consequent_intervals_not_overlap?(OpenClosedInterval.new(1,4), Point.new(5))).to be_truthy }
    it{ expect(helpers.consequent_intervals_not_overlap?(Point.new(4), Point.new(5))).to be_truthy }
    it{ expect(helpers.consequent_intervals_not_overlap?(OpenOpenInterval.new(1,6), Point.new(5))).to be_falsy }
    it{ expect(helpers.consequent_intervals_not_overlap?(OpenClosedInterval.new(1,5), Point.new(5))).to be_falsy }
    it{ expect(helpers.consequent_intervals_not_overlap?(Point.new(5), Point.new(5))).to be_falsy }
  end

  describe '#consequent_intervals_adjacent?' do
    it{ expect(helpers.consequent_intervals_adjacent?(OpenOpenInterval.new(1,5), OpenOpenInterval.new(5,7))).to be_falsy }
    it{ expect(helpers.consequent_intervals_adjacent?(OpenClosedInterval.new(1,5), OpenOpenInterval.new(5,7))).to be_truthy }
    it{ expect(helpers.consequent_intervals_adjacent?(OpenOpenInterval.new(1,5), ClosedOpenInterval.new(5,7))).to be_truthy }
    it{ expect(helpers.consequent_intervals_adjacent?(OpenClosedInterval.new(1,5), ClosedOpenInterval.new(5,7))).to be_falsy }
    it{ expect(helpers.consequent_intervals_adjacent?(OpenOpenInterval.new(1,5), Point.new(5))).to be_truthy }
    it{ expect(helpers.consequent_intervals_adjacent?(OpenClosedInterval.new(1,5), Point.new(5))).to be_falsy }
    it{ expect(helpers.consequent_intervals_adjacent?(OpenClosedInterval.new(1,4), Point.new(5))).to be_falsy }
    it{ expect(helpers.consequent_intervals_adjacent?(OpenClosedInterval.new(1,6), Point.new(5))).to be_falsy }
    
    it{ expect(helpers.consequent_intervals_adjacent?(OpenClosedInterval.new(1,5), ClosedClosedInterval.new(4,7))).to be_falsy }
    it{ expect(helpers.consequent_intervals_adjacent?(OpenClosedInterval.new(1,5), ClosedClosedInterval.new(6,7))).to be_falsy }
    it{ expect(helpers.consequent_intervals_adjacent?(OpenClosedInterval.new(1,5), ClosedClosedInterval.new(2,3))).to be_falsy }
    it{ expect(helpers.consequent_intervals_adjacent?(Point.new(4), Point.new(5))).to be_falsy }
  end

  describe '#glue adjacent' do
    it{ expect(helpers.glue_adjacent([])).to eq([])  }
    it{ expect(helpers.glue_adjacent([OpenOpenInterval.new(1,5), Point.new(5)])).to eq([OpenClosedInterval.new(1,5)])  }
    it{ expect(helpers.glue_adjacent([OpenOpenInterval.new(1,5), Point.new(5), OpenOpenInterval.new(5,7)])).to eq([OpenOpenInterval.new(1,7)])  }

    it{ expect(helpers.glue_adjacent([OpenOpenInterval.new(1,5), OpenOpenInterval.new(5,7)])).to eq([OpenOpenInterval.new(1,5), OpenOpenInterval.new(5,7)])  }
    
    it{ expect(helpers.glue_adjacent([OpenOpenInterval.new(1,5), ClosedOpenInterval.new(5,7)])).to eq([OpenOpenInterval.new(1,7)])  }
    it{ expect(helpers.glue_adjacent([OpenClosedInterval.new(1,5), OpenOpenInterval.new(5,7)])).to eq([OpenOpenInterval.new(1,7)])  }
    it{ expect(helpers.glue_adjacent([ClosedClosedInterval.new(1,5), OpenOpenInterval.new(5,7)])).to eq([ClosedOpenInterval.new(1,7)])  }
    it{ expect(helpers.glue_adjacent([OpenClosedInterval.new(1,5), OpenClosedInterval.new(5,7)])).to eq([OpenClosedInterval.new(1,7)])  }
    
    it{ expect(helpers.glue_adjacent([OpenClosedInterval.new(1,5), OpenOpenInterval.new(5,7), ClosedOpenInterval.new(7,8)])).to eq([OpenOpenInterval.new(1,8)])  }
    it{ expect(helpers.glue_adjacent([OpenClosedInterval.new(1,5), OpenOpenInterval.new(5,7), ClosedOpenInterval.new(7,8), OpenOpenInterval.new(9,10)])).to eq([OpenOpenInterval.new(1,8), OpenOpenInterval.new(9,10)])  }
    
    it{ expect(helpers.glue_adjacent([OpenOpenInterval.new(1,5), OpenOpenInterval.new(6,7)])).to eq([OpenOpenInterval.new(1,5), OpenOpenInterval.new(6,7)])  }
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
      end
    end
  end


  describe '#intersect'  do
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
        expect( interval_1.intersect(interval_2) ).to eq answer
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
