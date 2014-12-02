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
end
