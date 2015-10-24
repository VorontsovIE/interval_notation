require_relative '../lib/interval_notation'

include IntervalNotation
include IntervalNotation::Syntax::Short

interval_set_vs_segmentation = {
  'for non-empty interval set' => [
    cc(0,3) | oo(4,5) | oc(5,10) | co(12,15),
    Segmentation.new([
      Segmentation::Segment.new(lt_basic(0), false),
      Segmentation::Segment.new(cc_basic(0,3), true),
      Segmentation::Segment.new(oc_basic(3,4), false),
      Segmentation::Segment.new(oo_basic(4,5), true),
      Segmentation::Segment.new(pt_basic(5), false),
      Segmentation::Segment.new(oc_basic(5,10), true),
      Segmentation::Segment.new(oo_basic(10,12), false),
      Segmentation::Segment.new(co_basic(12,15), true),
      Segmentation::Segment.new(ge_basic(15), false),
    ])
  ],
  'for empty interval set' => [
    Empty,
    Segmentation.new([
      Segmentation::Segment.new(oo_basic(-Float::INFINITY, Float::INFINITY), false)
    ])
  ],
  'for entire R interval set' => [
    R,
    Segmentation.new([
      Segmentation::Segment.new(oo_basic(-Float::INFINITY, Float::INFINITY), true)
    ])
  ],
  'for a single point' => [
    pt(3),
    Segmentation.new([
      Segmentation::Segment.new(lt_basic(3), false),
      Segmentation::Segment.new(pt_basic(3), true),
      Segmentation::Segment.new(gt_basic(3), false),
    ])
  ],
  'for left-infinite interval set' => [
    lt(3) | oo(5,10),
    Segmentation.new([
      Segmentation::Segment.new(lt_basic(3), true),
      Segmentation::Segment.new(cc_basic(3,5), false),
      Segmentation::Segment.new(oo_basic(5,10), true),
      Segmentation::Segment.new(ge_basic(10), false),
    ])
  ],
  'for right-infinite interval set' => [
    oo(5,10) | gt(15),
    Segmentation.new([
      Segmentation::Segment.new(le_basic(5), false),
      Segmentation::Segment.new(oo_basic(5,10), true),
      Segmentation::Segment.new(cc_basic(10,15), false),
      Segmentation::Segment.new(gt_basic(15), true),
    ])
  ],
  'for left- and right- infinite interval set' => [
    lt(3) | oo(5,10) | ge(15),
    Segmentation.new([
      Segmentation::Segment.new(lt_basic(3), true),
      Segmentation::Segment.new(cc_basic(3,5), false),
      Segmentation::Segment.new(oo_basic(5,10), true),
      Segmentation::Segment.new(co_basic(10,15), false),
      Segmentation::Segment.new(ge_basic(15), true),
    ])
  ],
}

describe IntervalNotation::Segmentation do
  describe '#make_interval_set' do
    interval_set_vs_segmentation.each do |example, (interval_set, segmentation)|
      it "#{example} returns corresponding segmentation" do
        expect(interval_set.make_segmentation).to eq(segmentation)
      end
    end
  end
end

describe IntervalNotation::IntervalSet do
  describe '#make_segmentation' do
    interval_set_vs_segmentation.each do |example, (interval_set, segmentation)|
      it "#{example} returns corresponding interval set" do
        expect(segmentation.make_interval_set).to eq(interval_set)
      end
    end
  end
end


describe IntervalNotation::Segmentation do
  let(:segmentation){
    Segmentation.new([
      Segmentation::Segment.new(lt_basic(0), :A),
      Segmentation::Segment.new(co_basic(0,3), :B),
      Segmentation::Segment.new(cc_basic(3,5), :C),
      Segmentation::Segment.new(oo_basic(5,7), :D),
      Segmentation::Segment.new(pt_basic(7), :E),
      Segmentation::Segment.new(oc_basic(7,10), :F),
      Segmentation::Segment.new(gt_basic(10), :G),
    ])
  }

  let(:segmentation_le_ge_infinite_segments){
    Segmentation.new([
      Segmentation::Segment.new(le_basic(0), :A),
      Segmentation::Segment.new(oo_basic(0,3), :B),
      Segmentation::Segment.new(cc_basic(3,5), :C),
      Segmentation::Segment.new(oo_basic(5,7), :D),
      Segmentation::Segment.new(pt_basic(7), :E),
      Segmentation::Segment.new(oo_basic(7,10), :F),
      Segmentation::Segment.new(ge_basic(10), :G),
    ])
  }

  describe '#segment_covering_point' do
    specify 'returns segment' do
      expect(segmentation.segment_covering_point(2)).to eq Segmentation::Segment.new(co_basic(0,3), :B)
    end
    specify 'works for general position case in closed-open interval' do
      expect(segmentation.segment_covering_point(2).state).to eq(:B)
    end
    specify 'works for general position case in closed-closed interval' do
      expect(segmentation.segment_covering_point(4).state).to eq(:C)
    end
    specify 'works for general position case in open-open interval' do
      expect(segmentation.segment_covering_point(6).state).to eq(:D)
    end
    specify 'works for general position case in open-closed interval' do
      expect(segmentation.segment_covering_point(8).state).to eq(:F)
    end
    specify 'works for general position case in less-than interval' do
      expect(segmentation.segment_covering_point(-1).state).to eq(:A)
    end
    specify 'works for general position case in greater-than interval' do
      expect(segmentation.segment_covering_point(11).state).to eq(:G)
    end
    specify 'works for general position case in less-than-or-equal-to interval' do
      expect(segmentation_le_ge_infinite_segments.segment_covering_point(-1).state).to eq(:A)
    end
    specify 'works for general position case in greater-than-or-equal-to interval' do
      expect(segmentation_le_ge_infinite_segments.segment_covering_point(11).state).to eq(:G)
    end
    specify 'works for singular point segment' do
      expect(segmentation.segment_covering_point(7).state).to eq(:E)
    end

    specify 'works for leftmost boundary in closed-open interval' do
      expect(segmentation.segment_covering_point(0).state).to eq(:B)
    end
    specify 'works for rightmost boundary in open-closed interval' do
      expect(segmentation.segment_covering_point(10).state).to eq(:F)
    end
    specify 'works for leftmost boundary in closed-closed interval' do
      expect(segmentation.segment_covering_point(3).state).to eq(:C)
    end
    specify 'works for rightmost boundary in closed-closed interval' do
      expect(segmentation.segment_covering_point(5).state).to eq(:C)
    end

    specify 'works for rightmost boundary in less-than interval' do
      expect(segmentation.segment_covering_point(0).state).to eq(:B)
    end
    specify 'works for leftmost boundary in greater-than interval' do
      expect(segmentation.segment_covering_point(10).state).to eq(:F)
    end


    specify 'works for rightmost boundary in less-than-or-equal-to interval' do
      expect(segmentation_le_ge_infinite_segments.segment_covering_point(0).state).to eq(:A)
    end
    specify 'works for leftmost boundary in greater-than-or-equal-to interval' do
      expect(segmentation_le_ge_infinite_segments.segment_covering_point(10).state).to eq(:G)
    end
  end
end
