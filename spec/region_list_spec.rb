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
      Then{ region_list.to_s.should == 'chr1,-:<(113..117;100..110;93..97>' }
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

end