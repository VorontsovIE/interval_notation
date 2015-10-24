require_relative '../lib/interval_notation'

include IntervalNotation
include IntervalNotation::Syntax::Short

describe IntervalNotation::SweepLine do
  describe '#make_segmentation' do

    describe 'SingleTagging' do
      specify 'When tags are all different' do
        tagged_intervals = [[oo(0,10), :A], [cc(0,8), :B], [oo(5,15), :C]]
        segmentation = SweepLine.make_tagging(tagged_intervals)
        expected_result = Segmentation.new([
          Segmentation::Segment.new(lt_basic(0), Set.new),
          Segmentation::Segment.new(pt_basic(0), Set.new([:B])),
          Segmentation::Segment.new(oc_basic(0,5), Set.new([:A,:B])),
          Segmentation::Segment.new(oc_basic(5,8), Set.new([:A,:B,:C])),
          Segmentation::Segment.new(oo_basic(8,10), Set.new([:A,:C])),
          Segmentation::Segment.new(co_basic(10,15), Set.new([:C])),
          Segmentation::Segment.new(ge_basic(15), Set.new),
        ])
        expect(segmentation).to eq(expected_result)
      end
      specify 'When some tags are the same' do
        tagged_intervals = [[oo(0,10), :A], [cc(0,8), :B], [oo(5,15), :A]]
        segmentation = SweepLine.make_tagging(tagged_intervals)
        expected_result = Segmentation.new([
          Segmentation::Segment.new(lt_basic(0), Set.new),
          Segmentation::Segment.new(pt_basic(0), Set.new([:B])),
          Segmentation::Segment.new(oc_basic(0,8), Set.new([:A,:B])),
          Segmentation::Segment.new(oo_basic(8,15), Set.new([:A])),
          Segmentation::Segment.new(ge_basic(15), Set.new),
        ])
        expect(segmentation).to eq(expected_result)
      end
    end

    describe 'MultiTagging' do
      specify 'When tags are all different' do
        tagged_intervals = [[oo(0,10), :A], [cc(0,8), :B], [oo(5,15), :C]]
        segmentation = SweepLine.make_multitagging(tagged_intervals)
        expected_result = Segmentation.new([
          Segmentation::Segment.new(lt_basic(0), {}),
          Segmentation::Segment.new(pt_basic(0), {:B => 1}),
          Segmentation::Segment.new(oc_basic(0,5), {:A => 1, :B => 1}),
          Segmentation::Segment.new(oc_basic(5,8), {:A => 1, :B => 1, :C => 1}),
          Segmentation::Segment.new(oo_basic(8,10), {:A => 1, :C => 1}),
          Segmentation::Segment.new(co_basic(10,15), {:C => 1}),
          Segmentation::Segment.new(ge_basic(15), {}),
        ])
        expect(segmentation).to eq(expected_result)
      end
      specify 'When some tags are the same' do
        tagged_intervals = [[oo(0,10), :A], [cc(0,8), :B], [oo(5,15), :A]]
        segmentation = SweepLine.make_multitagging(tagged_intervals)
        expected_result = Segmentation.new([
          Segmentation::Segment.new(lt_basic(0), {}),
          Segmentation::Segment.new(pt_basic(0), {:B => 1}),
          Segmentation::Segment.new(oc_basic(0,5), {:A => 1, :B => 1}),
          Segmentation::Segment.new(oc_basic(5,8), {:A => 2, :B => 1}),
          Segmentation::Segment.new(oo_basic(8,10), {:A => 2}),
          Segmentation::Segment.new(co_basic(10,15), {:A => 1}),
          Segmentation::Segment.new(ge_basic(15), {}),
        ])
        expect(segmentation).to eq(expected_result)
      end
    end
  end
end
