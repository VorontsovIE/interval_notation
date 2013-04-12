$:.unshift File.dirname(File.expand_path(__FILE__, '../lib'))
require 'region_list'
require 'rspec/given'

describe RegionList do
  describe '#initialize' do
    Given(:region){ Region.new('chr1', '+', 100, 110) }
    Given(:same_region){ Region.new('chr1', '+', 100, 110) }
    Given(:region_from_left){ Region.new('chr1', '+', 93, 97) }
    Given(:region_from_left_joint){ Region.new('chr1', '+', 93, 100) }
    Given(:region_from_right){ Region.new('chr1', '+', 113, 117) }

    Given(:region_minus_strand){ Region.new('chr1', '-', 100, 110) }
    Given(:region_from_left_minus_strand){ Region.new('chr1', '-', 93, 97) }
    Given(:region_from_right_minus_strand){ Region.new('chr1', '-', 113, 117) }

    Given(:region_from_right_joint){ Region.new('chr1', '+', 110, 117) }
    Given(:intersecting_region){ Region.new('chr1', '+', 107, 113) }
    Given(:inside_region){ Region.new('chr1', '+', 103, 107) }
    Given(:nonintersecting_region_on_another_strand){ Region.new('chr1', '-', 113, 117) }
    Given(:nonintersecting_region_on_another_chromosome){ Region.new('chrY', '+', 113, 117) }

    context 'with no regions' do
      When(:region_list) { RegionList.new() }
      Then{ region_list.should_not have_failed }
      Then{ region_list.list_of_regions.should == [] }
      Then{ region_list.should be_empty }
      Then{ region_list.chromosome.should be_nil }
      Then{ region_list.strand.should be_nil }
      Then{ region_list.to_s.should == '' }

      context 'empty region list created with intersection' do
        Given(:empty_region_list) { RegionList.new( Region.new_by_annotation('chr1:100..110,+') ).intersection(Region.new_by_annotation('chr1:200..210,+'))}
        Then{ empty_region_list.should be_empty }
        Then{ empty_region_list.chromosome.should be_nil }
        Then{ empty_region_list.strand.should be_nil }
      end

    end
    context 'with one region' do
      When(:region_list) { RegionList.new(region) }
      Then{ region_list.should_not have_failed }
      Then{ region_list.list_of_regions.should == [region] }
      Then{ region_list.should_not be_empty }
      Then{ region_list.chromosome.should == 'chr1' }
      Then{ region_list.strand.should == '+' }
      Then{ region_list.to_s.should == 'chr1,+:<100..110>' }
    end
    context 'with several non-intersecting regions' do
      When(:region_list) { RegionList.new(region, region_from_right, region_from_left) }
      Then{ region_list.should_not have_failed }
      Then{ region_list.list_of_regions.should == [region_from_left, region, region_from_right] }
      Then{ region_list.should_not be_empty }
      Then{ region_list.chromosome.should == 'chr1' }
      Then{ region_list.strand.should == '+' }
      Then{ region_list.to_s.should == 'chr1,+:<93..97;100..110;113..117>' }
    end
    context 'with several non-intersecting regions on minus-strand' do
      When(:region_list) { RegionList.new(region_minus_strand, region_from_right_minus_strand, region_from_left_minus_strand) }
      Then{ region_list.should_not have_failed }
      Then{ region_list.list_of_regions.should == [region_from_right_minus_strand, region_minus_strand, region_from_left_minus_strand] }
      Then{ region_list.strand.should == '-' }
      Then{ region_list.to_s.should == 'chr1,-:<113..117;100..110;93..97>' }
    end
    context 'with several non-intersecting regions jointed' do
      When(:region_list) { RegionList.new(region, region_from_right_joint, region_from_left_joint) }
      Then{ region_list.should_not have_failed }
      Then{ region_list.list_of_regions.should == [region_from_left_joint, region, region_from_right_joint] }
    end


    context 'with several nonintersecting regions and region lists' do
      Given(:region_list_1) { RegionList.new(region_from_right, region_from_left) }
      When(:region_list) { RegionList.new(region_list_1, region) }
      Then{ region_list.should_not have_failed }
      Then{ region_list.list_of_regions.should == [region_from_left, region, region_from_right] }
    end

    context 'with several nonintersecting region lists' do
      Given(:region_list_1) { RegionList.new(region_from_right, region_from_left) }
      Given(:region_list_2) { RegionList.new(region) }
      When(:region_list) { RegionList.new(region_list_1, region_list_2) }
      Then{ region_list.should_not have_failed }
      Then{ region_list.list_of_regions.should == [region_from_left, region, region_from_right] }
    end
    context 'with several duplicated regions' do
      When(:region_list) { RegionList.new(region, region_from_left, same_region, region_from_right) }
      Then{ region_list.should_not have_failed }
      Then{ region_list.list_of_regions.should == [region_from_left, region, region_from_right] }
    end


    context 'with several regions on different strands' do
      When(:region_list) { RegionList.new(region, nonintersecting_region_on_another_strand) }
      Then { region_list.should have_failed }
    end
    context 'with several regions on different chromosomes' do
      When(:region_list) { RegionList.new(region, nonintersecting_region_on_another_chromosome) }
      Then { region_list.should have_failed }
    end
    context 'with several intersecting regions' do
      context '(region lasting from inside to outside)' do
        When(:region_list) { RegionList.new(region, intersecting_region) }
        Then { region_list.should have_failed }
      end
      context '(region inside of another region)' do
        When(:region_list) { RegionList.new(region, inside_region) }
        Then { region_list.should have_failed }
      end
    end
    context 'with several intersecting region lists' do
      Given(:region_list_1) { RegionList.new(intersecting_region, region_from_left) }
      Given(:region_list_2) { RegionList.new(region) }
      When(:region_list) { RegionList.new(region_list_1, region_list_2) }
      Then{ region_list.should have_failed }
    end
  end

  describe 'intersection' do
    Given(:region_embedded) { Region.new_by_annotation('chr1:103..107,+') }
    Given(:region_intersecting_a_segment_of_list) { Region.new_by_annotation('chr1:97..103,+') }
    Given(:region_intersecting_several_segments_of_list) { Region.new_by_annotation('chr1:97..117,+') }
    Given(:region_intersecting_nothing) { Region.new_by_annotation('chr1:87..97,+') }
    Given(:region_on_another_chromosome) { Region.new_by_annotation('chr2:103..107,+') }
    Given(:region_on_another_strand) { Region.new_by_annotation('chr1:103..107,-') }

    context 'empty region list' do
      Given(:region_list) { RegionList.new }

      Then{ region_list.intersection(region_embedded).should be_empty }
      Then{ region_list.intersection(region_intersecting_a_segment_of_list).should be_empty }
      Then{ region_list.intersection(region_intersecting_several_segments_of_list).should be_empty }
      Then{ region_list.intersection(region_intersecting_nothing).should be_empty }
      Then{ region_list.intersection(region_on_another_chromosome).should be_empty }
      Then{ region_list.intersection(region_on_another_strand).should be_empty }
    end

    context 'contigious region list' do
      Given(:region_list) { RegionList.new(Region.new_by_annotation('chr1:100..108,+')) }

      Then{ region_list.intersection(region_embedded).should == RegionList.new( Region.new_by_annotation('chr1:103..107,+') ) }
      Then{ region_list.intersection(region_intersecting_a_segment_of_list).should == RegionList.new( Region.new_by_annotation('chr1:100..103,+') ) }
      Then{ region_list.intersection(region_intersecting_several_segments_of_list).should == RegionList.new( Region.new_by_annotation('chr1:100..108,+') ) }
      Then{ region_list.intersection(region_intersecting_nothing).should be_empty }
      Then{ region_list.intersection(region_on_another_chromosome).should be_empty }
      Then{ region_list.intersection(region_on_another_strand).should be_empty }
    end

    context 'region list containing several contigious regions' do
      Given(:region_list) { RegionList.new(Region.new_by_annotation('chr1:100..108,+'), Region.new_by_annotation('chr1:115..120,+'), Region.new_by_annotation('chr1:130..142,+')) }

      Then{ region_list.intersection(region_embedded).should == RegionList.new( Region.new_by_annotation('chr1:103..107,+') ) }
      Then{ region_list.intersection(region_intersecting_a_segment_of_list).should == RegionList.new( Region.new_by_annotation('chr1:100..103,+') ) }
      Then{ region_list.intersection(region_intersecting_several_segments_of_list).should == RegionList.new( Region.new_by_annotation('chr1:100..108,+'), Region.new_by_annotation('chr1:115..117,+') ) }
      Then{ region_list.intersection(region_intersecting_nothing).should be_empty }
      Then{ region_list.intersection(region_on_another_chromosome).should be_empty }
      Then{ region_list.intersection(region_on_another_strand).should be_empty }
    end

  end

  describe 'equality operations' do
    Given(:region_1){ Region.new_by_annotation('chr1:100..110,+') }
    Given(:region_2){ Region.new_by_annotation('chr1:113..117,+') }
    Given(:region_3){ Region.new_by_annotation('chr1:120..132,+') }

    Given(:empty_region_list) { RegionList.new }
    Given(:same_empty_region_list) { RegionList.new }

    Given(:contigious_region_list) { RegionList.new(region_1) }
    Given(:same_contigious_region_list) { RegionList.new(region_1) }
    Given(:another_contigious_region_list) { RegionList.new(region_2) }

    Given(:non_contigious_region_list) { RegionList.new(region_1, region_2) }
    Given(:same_non_contigious_region_list) { RegionList.new(region_1, region_2) }
    Given(:another_non_contigious_region_list) { RegionList.new(region_1, region_3) }

    describe '==' do
      Then{ empty_region_list.should == same_empty_region_list }
      Then{ contigious_region_list.should == same_contigious_region_list }
      Then{ non_contigious_region_list.should == same_non_contigious_region_list }

      Then{ contigious_region_list.should_not == another_contigious_region_list }
      Then{ non_contigious_region_list.should_not == another_non_contigious_region_list }

      Then{ empty_region_list.should_not == non_contigious_region_list }
      Then{ empty_region_list.should_not == contigious_region_list }
      Then{ contigious_region_list.should_not == non_contigious_region_list }
    end

    describe 'hash/eql? ability' do
      Given(:hash_by_region_list) { {empty_region_list => 'first region list', contigious_region_list => 'another region list', non_contigious_region_list => 'third region list'} }

      Then{ hash_by_region_list.should have_key(empty_region_list) }
      Then{ hash_by_region_list.should have_key(contigious_region_list) }
      Then{ hash_by_region_list.should have_key(non_contigious_region_list) }

      Then{ hash_by_region_list.should have_key(same_empty_region_list) }
      Then{ hash_by_region_list.should have_key(same_contigious_region_list) }
      Then{ hash_by_region_list.should have_key(same_non_contigious_region_list) }

      Then{ hash_by_region_list.should_not have_key(another_contigious_region_list) }
      Then{ hash_by_region_list.should_not have_key(another_non_contigious_region_list) }

      Then{ hash_by_region_list[non_contigious_region_list].should be_eql hash_by_region_list[same_non_contigious_region_list] }
    end
  end
end