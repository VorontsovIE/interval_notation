require 'interval_notation/interval_notation'

def oo(from, to); Interval.oo(from, to); end
def oc(from, to); Interval.oc(from, to); end
def co(from, to); Interval.co(from, to); end
def cc(from, to); Interval.cc(from, to); end
def pt(value); Interval.pt(value); end
def inttree(*intervals); IntervalTree.new(intervals); end

describe IntervalTree::Helpers do
  let(:helpers) { IntervalTree::Helpers }

  describe '#consequent_intervals_not_overlap?' do
    it{ expect(helpers.consequent_intervals_not_overlap?(oo(1,5), oo(5,7))).to be_truthy }
    it{ expect(helpers.consequent_intervals_not_overlap?(oc(1,5), oo(5,7))).to be_truthy }
    it{ expect(helpers.consequent_intervals_not_overlap?(oo(1,5), co(5,7))).to be_truthy }
    it{ expect(helpers.consequent_intervals_not_overlap?(oc(1,5), co(5,7))).to be_falsy }
    
    it{ expect(helpers.consequent_intervals_not_overlap?(oc(1,5), cc(6,7))).to be_truthy }
    it{ expect(helpers.consequent_intervals_not_overlap?(oc(1,5), cc(4,7))).to be_falsy }
    it{ expect(helpers.consequent_intervals_not_overlap?(oc(1,5), cc(2,3))).to be_falsy }
    
    it{ expect(helpers.consequent_intervals_not_overlap?(oo(1,5), pt(5))).to be_truthy }
    it{ expect(helpers.consequent_intervals_not_overlap?(oo(1,4), pt(5))).to be_truthy }
    it{ expect(helpers.consequent_intervals_not_overlap?(oc(1,4), pt(5))).to be_truthy }
    it{ expect(helpers.consequent_intervals_not_overlap?(pt(4), pt(5))).to be_truthy }
    it{ expect(helpers.consequent_intervals_not_overlap?(oo(1,6), pt(5))).to be_falsy }
    it{ expect(helpers.consequent_intervals_not_overlap?(oc(1,5), pt(5))).to be_falsy }
    it{ expect(helpers.consequent_intervals_not_overlap?(pt(5), pt(5))).to be_falsy }
  end

  describe '#consequent_intervals_adjacent?' do
    it{ expect(helpers.consequent_intervals_adjacent?(oo(1,5), oo(5,7))).to be_falsy }
    it{ expect(helpers.consequent_intervals_adjacent?(oc(1,5), oo(5,7))).to be_truthy }
    it{ expect(helpers.consequent_intervals_adjacent?(oo(1,5), co(5,7))).to be_truthy }
    it{ expect(helpers.consequent_intervals_adjacent?(oc(1,5), co(5,7))).to be_falsy }
    it{ expect(helpers.consequent_intervals_adjacent?(oo(1,5), pt(5))).to be_truthy }
    it{ expect(helpers.consequent_intervals_adjacent?(oc(1,5), pt(5))).to be_falsy }
    it{ expect(helpers.consequent_intervals_adjacent?(oc(1,4), pt(5))).to be_falsy }
    it{ expect(helpers.consequent_intervals_adjacent?(oc(1,6), pt(5))).to be_falsy }
    
    it{ expect(helpers.consequent_intervals_adjacent?(oc(1,5), cc(4,7))).to be_falsy }
    it{ expect(helpers.consequent_intervals_adjacent?(oc(1,5), cc(6,7))).to be_falsy }
    it{ expect(helpers.consequent_intervals_adjacent?(oc(1,5), cc(2,3))).to be_falsy }
    it{ expect(helpers.consequent_intervals_adjacent?(pt(4), pt(5))).to be_falsy }
  end

  describe '#glue adjacent' do
    it{ expect(helpers.glue_adjacent([])).to eq([])  }
    it{ expect(helpers.glue_adjacent([oo(1,5), pt(5)])).to eq([oc(1,5)])  }
    it{ expect(helpers.glue_adjacent([oo(1,5), pt(5), oo(5,7)])).to eq([oo(1,7)])  }

    it{ expect(helpers.glue_adjacent([oo(1,5), oo(5,7)])).to eq([oo(1,5), oo(5,7)])  }
    
    it{ expect(helpers.glue_adjacent([oo(1,5), co(5,7)])).to eq([oo(1,7)])  }
    it{ expect(helpers.glue_adjacent([oc(1,5), oo(5,7)])).to eq([oo(1,7)])  }
    it{ expect(helpers.glue_adjacent([cc(1,5), oo(5,7)])).to eq([co(1,7)])  }
    it{ expect(helpers.glue_adjacent([oc(1,5), oc(5,7)])).to eq([oc(1,7)])  }
    
    it{ expect(helpers.glue_adjacent([oc(1,5), oo(5,7), co(7,8)])).to eq([oo(1,8)])  }
    it{ expect(helpers.glue_adjacent([oc(1,5), oo(5,7), co(7,8), oo(9,10)])).to eq([oo(1,8), oo(9,10)])  }
    
    it{ expect(helpers.glue_adjacent([oo(1,5), oo(6,7)])).to eq([oo(1,5), oo(6,7)])  }
  end

  describe '#union'  do
    {
      [inttree(oo(1,3),oo(3,5)), inttree(oo(2,3),oo(3,7))] => inttree(oo(1,3),oo(3,7)),
      [inttree(oo(1,5)), inttree(oo(2,3),oo(3,7))] => inttree(oo(1,7)),
      [inttree(oo(1,3),oo(3,5)), inttree(oo(2,7))] => inttree(oo(1,7)),
        
      [inttree(oo(1,3)), inttree()] => inttree(oo(1,3)),
      [inttree(oo(1,3)), inttree(oo(5,6))] => inttree(oo(1,3), oo(5,6)),
      [inttree(oo(1,3)), inttree(oo(3,6))] => inttree(oo(1,3), oo(3,6)),
      [inttree(oo(1,3)), inttree(oo(2,6))] => inttree(oo(1,6)),
      [inttree(oc(1,3)), inttree(co(5,6))] => inttree(oc(1,3), co(5,6)),
      [inttree(cc(1,3)), inttree(oc(5,6))] => inttree(cc(1,3), oc(5,6)),
      [inttree(oo(1,3)), inttree(co(3,6))] => inttree(oo(1,6)),
      [inttree(oo(1,3)), inttree(oo(2,3))] => inttree(oo(1,3)),
      [inttree(oo(1,3)), inttree(oc(2,3))] => inttree(oc(1,3)),
      [inttree(oc(1,3)), inttree(oo(2,3))] => inttree(oc(1,3)),
      [inttree(oo(1,3)), inttree(oo(1,3))] => inttree(oo(1,3)),
      [inttree(oo(1,3)), inttree(oo(0,4))] => inttree(oo(0,4)),
      [inttree(oo(0,4)), inttree(oo(1,3))] => inttree(oo(0,4)),
      [inttree(oo(1,3),oo(3,5)), inttree(pt(3))] => inttree(oo(1,5)),

      [inttree(oo(1,3)), inttree(pt(2))] => inttree(oo(1,3)),
      [inttree(oo(1,3)), inttree(pt(1))] => inttree(co(1,3)),
      [inttree(co(1,3)), inttree(pt(1))] => inttree(co(1,3)),
      [inttree(oo(1,3)), inttree(pt(0))] => inttree(pt(0),oo(1,3)),

      [inttree(oo(1,3),oo(5,7)), inttree(oo(3,5))] => inttree(oo(1,3),oo(3,5),oo(5,7)),
      [inttree(oo(1,3),oo(5,7)), inttree(co(3,5))] => inttree(oo(1,5),oo(5,7)),
      [inttree(oo(1,3),oo(5,7)), inttree(cc(3,5))] => inttree(oo(1,7)),
      [inttree(oo(-Float::INFINITY,3)), inttree(oo(2,Float::INFINITY))] => inttree(oo(-Float::INFINITY,Float::INFINITY)),
      [inttree(oo(-Float::INFINITY,3)), inttree(oo(4,Float::INFINITY))] => inttree(oo(-Float::INFINITY,3),oo(4,Float::INFINITY)),
      [inttree(oo(-Float::INFINITY,3)), inttree(co(3,Float::INFINITY))] => inttree(oo(-Float::INFINITY,Float::INFINITY)),
    }.each do |(interval_1, interval_2), answer|
      it "#{interval_1} | #{interval_2} should equal #{answer}" do
        expect( interval_1.union(interval_2) ).to eq answer
      end
    end
  end


  describe '#intersect'  do
    {
      [inttree(oo(1,3),oo(3,5)), inttree(oo(2,3),oo(3,7))] => inttree(oo(2,3),oo(3,5)),
      [inttree(oo(1,3),oo(3,5)), inttree(oo(2,7))] => inttree(oo(2,3),oo(3,5)),

      [inttree(oo(1,3)), inttree(oo(2,5))] => inttree(oo(2,3)),
      [inttree(oo(1,3)), inttree(oo(4,5))] => inttree(),

      [inttree(oo(1,3)), inttree(oo(3,5))] => inttree(),
      [inttree(oo(1,3)), inttree(co(3,5))] => inttree(),
      [inttree(oc(1,3)), inttree(oo(3,5))] => inttree(),
      [inttree(oc(1,3)), inttree(co(3,5))] => inttree(pt(3)),

      [inttree(oo(2,6)), inttree(oo(1,3),co(5,7))] => inttree(oo(2,3),co(5,6)),
      [inttree(oo(1,6)), inttree(oo(1,3),co(5,7))] => inttree(oo(1,3),co(5,6)),
      [inttree(oo(0,6)), inttree(oo(1,3),co(5,7))] => inttree(oo(1,3),co(5,6)),
      [inttree(oo(0,6)), inttree(oo(1,3),co(5,6))] => inttree(oo(1,3),co(5,6)),
        
      [inttree(oo(1,3)), inttree(pt(2))] => inttree(pt(2)),
      [inttree(oo(1,3)), inttree(pt(1))] => inttree(),
      [inttree(co(1,3)), inttree(pt(0))] => inttree(),
      [inttree(co(1,3)), inttree(pt(1))] => inttree(pt(1)),

    }.each do |(interval_1, interval_2), answer|
      it "#{interval_1} & #{interval_2} should equal #{answer}" do
        expect( interval_1.intersect(interval_2) ).to eq answer
      end
    end
  end

  describe '#subtract' do
    {
      [inttree(oo(1,5),oo(6,8)),inttree(oo(1,5))] => inttree(oo(6,8)),
      [inttree(oo(1,5),oo(6,8)),inttree(oo(1,8))] => inttree(),
      [inttree(oo(1,5),oo(6,8)),inttree(cc(1,5))] => inttree(oo(6,8)),
      [inttree(oo(1,5)),inttree(cc(2,3))] => inttree(oo(1,2),oo(3,5)),
      [inttree(oo(1,5)),inttree(oo(2,3))] => inttree(oc(1,2),co(3,5)),
      [inttree(oo(1,5)),inttree(oo(1,3))] => inttree(co(3,5)),
      [inttree(oo(1,5)),inttree(pt(0))] => inttree(oo(1,5)),
      [inttree(oo(1,5)),inttree(pt(1))] => inttree(oo(1,5)),
      [inttree(co(1,5)),inttree(pt(1))] => inttree(oo(1,5)),
      [inttree(oo(1,5)),inttree(pt(3))] => inttree(oo(1,3),oo(3,5)),
      [inttree(cc(1,5)),inttree(oo(1,3))] => inttree(pt(1),cc(3,5)),
      [inttree(cc(1,5)),inttree(co(1,3))] => inttree(cc(3,5)),
      [inttree(oo(1,5)),inttree(cc(1,3))] => inttree(oo(3,5)),
      [inttree(oo(1,5)),inttree(oo(0,3))] => inttree(co(3,5)),
      [inttree(oo(1,5)),inttree(oo(0,2),oo(3,4))] => inttree(cc(2,3),co(4,5)),
      [inttree(oo(-Float::INFINITY,Float::INFINITY)),inttree(oo(1,5))] => inttree(oc(-Float::INFINITY,1),co(5,Float::INFINITY)),
      [inttree(oo(1,5)), inttree(oo(-Float::INFINITY,Float::INFINITY))] => inttree(),
    }.each do |(interval_1, interval_2), answer|
      it "#{interval_1} - #{interval_2} should equal #{answer}" do
        expect( interval_1.subtract(interval_2) ).to eq answer
      end
    end
  end
end
