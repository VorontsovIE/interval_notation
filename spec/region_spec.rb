$:.unshift File.dirname(File.expand_path(__FILE__, '../lib'))
require 'region'
require 'rspec/given'

describe Region do
  describe '#initialize' do
    describe 'with start < end' do
      When(:region) { Region.new('chr1', '+', 100, 110) }
      Then { region.should_not have_failed }
    end
    describe 'with start > end' do
      When(:region) { Region.new('chr1', '+', 100, 97) }
      Then { region.should have_failed }
    end
    describe 'with start == end' do
      When(:region) { Region.new('chr1', '+', 100, 100) }
      Then { region.should have_failed }
    end
  end

  Given(:region) { Region.new('chr1', '+', 100, 110) }

  Given(:same_region) { Region.new('chr1', '+', 100, 110) }

  Given(:region_inside) { Region.new('chr1', '+', 103, 107) }
  Given(:region_inside_extend_to_end) { Region.new('chr1', '+', 103, 110) }
  Given(:region_inside_extend_from_start) { Region.new('chr1', '+', 100, 103) }

  Given(:region_on_another_strand) { Region.new('chr1', '-', 103, 107) }
  Given(:region_on_another_chromosome) { Region.new('chr2', '+', 103, 107) }

  Given(:region_from_inside_to_outside_after_end) { Region.new('chr1', '+', 103, 113) }
  Given(:region_from_outside_before_start_to_inside) { Region.new('chr1', '+', 97, 103) }

  Given(:region_containing) { Region.new('chr1', '+', 97, 113) }

  Given(:region_outside_left) { Region.new('chr1', '+', 97, 99) }
  Given(:region_outside_right) { Region.new('chr1', '+', 113, 117) }
  Given(:region_outside_extend_from_end) { Region.new('chr1', '+', 110, 113) }
  Given(:region_outside_extend_to_start) { Region.new('chr1', '+', 97, 100) }

  Given(:all_region_types) {
    [ region, same_region, region_inside, region_inside_extend_to_end, region_inside_extend_from_start,
    region_on_another_strand, region_on_another_chromosome,
    region_from_inside_to_outside_after_end, region_from_outside_before_start_to_inside,
    region_containing,
    region_outside_left, region_outside_right,
    region_outside_extend_from_end, region_outside_extend_to_start]
  }

  describe '#intersect?' do
    Then{
      all_region_types.each{|second_region|
        region.intersect?(second_region).should == second_region.intersect?(region)
      }
    }
    Then{
      all_region_types.each{|second_region|
        region.intersect?(second_region).should be_true  if region.intersection(second_region)
      }
    }
    Then{
      all_region_types.each{|second_region|
        region.intersect?(second_region).should be_false  unless region.intersection(second_region)
      }
    }
  end

  describe '#intersection' do
    Then{ region.intersection(region).should == region }
    Then{ region.intersection(same_region).should == region }

    Then{ region.intersection(region_inside).should == region_inside }
    Then{ region.intersection(region_inside_extend_to_end).should == region_inside_extend_to_end }
    Then{ region.intersection(region_inside_extend_from_start).should == region_inside_extend_from_start }

    Then{ region.intersection(region_on_another_strand).should == nil }
    Then{ region.intersection(region_on_another_chromosome).should == nil }

    Then{ region.intersection(region_from_inside_to_outside_after_end).should == Region.new('chr1', '+', 103, 110) }
    Then{ region.intersection(region_from_outside_before_start_to_inside).should == Region.new('chr1', '+', 100, 103) }

    Then{ region.intersection(region_containing).should == region }

    Then{ region.intersection(region_outside_left).should == nil }
    Then{ region.intersection(region_outside_right).should == nil }
    Then{ region.intersection(region_outside_extend_from_end).should == nil }
    Then{ region.intersection(region_outside_extend_to_start).should == nil }

    Then{
      all_region_types.each{|second_region|
        region.intersection(second_region).should == second_region.intersection(region)
      }
    }
  end

  describe '#contain?' do
    Then{ region.contain?(region).should be_true }
    Then{ region.contain?(same_region).should be_true }

    Then{ region.contain?(region_inside).should be_true }
    Then{ region.contain?(region_inside_extend_to_end).should be_true }
    Then{ region.contain?(region_inside_extend_from_start).should be_true }

    Then{ region.contain?(region_on_another_strand).should  be_false }
    Then{ region.contain?(region_on_another_chromosome).should be_false }

    Then{ region.contain?(region_from_inside_to_outside_after_end).should be_false }
    Then{ region.contain?(region_from_outside_before_start_to_inside).should be_false }

    Then{ region.contain?(region_containing).should be_false }


    Then{ region.contain?(region_outside_left).should be_false }
    Then{ region.contain?(region_outside_right).should  be_false }
    Then{ region.contain?(region_outside_extend_from_end).should be_false }
    Then{ region.contain?(region_outside_extend_to_start).should be_false }


  end

  describe '#annotation' do
    Then{ region.annotation.should == 'chr1:100..110,+' }
    Then{ region_on_another_chromosome.annotation.should == 'chr2:103..107,+' }
    Then{ region_on_another_strand.annotation.should == 'chr1:103..107,-' }
  end

  describe '#length' do
    Then {Region.new('chr1', '+', 103, 104).length == 1 }
    Then {Region.new('chr1', '+', 103, 106).length == 3 }
    Then {Region.new('chr1', '-', 103, 106).length == 3 }
  end

  describe '.new_by_annotation' do
    Then {
      all_region_types.each{|region|
        region.should == Region.new_by_annotation(region.annotation)
      }
    }
  end

  describe '==' do
    Given(:another_pos_start) { Region.new('chr1', '+', 103, 110) }
    Given(:another_pos_end) { Region.new('chr1', '+', 100, 107) }
    Given(:another_chromosome) { Region.new('chrY', '+', 100, 110) }
    Given(:another_strand) { Region.new('chr1', '-', 100, 110) }

    Then{ region.should == same_region}
    Then{ region.should_not == another_pos_start}
    Then{ region.should_not == another_pos_end}
    Then{ region.should_not == another_chromosome}
    Then{ region.should_not == another_strand}
  end

  describe 'hash/eql? ability' do
    Given(:hash_by_region) { {region => 'first region', region_inside => 'another region'} }

    Then{ hash_by_region.should have_key(region) }
    Then{ hash_by_region.should have_key(region) }
    Then{ hash_by_region.should have_key(same_region) }
    Then{ hash_by_region[region].should be_eql hash_by_region[same_region] }

    Then{ hash_by_region.should have_key(region_inside) }
    Then{ hash_by_region.should_not have_key(region_containing) }
  end

  describe 'Comparable' do
    Then{ (region <=> region_on_another_strand).should be_nil }
    Then{ (region <=> region_on_another_chromosome).should be_nil }
    
    shared_examples 'compare regions' do
      Then { (subject_region <=> same_as_subject_region).should == 0 }
      
      Then { (subject_region <=> region_right_to_subject).should == -1 }
      Then { (subject_region <=> region_left_to_subject).should == 1 }
      Then { (subject_region <=> region_right_to_subject_joint).should == -1 }
      Then { (subject_region <=> region_left_to_subject_joint).should == 1 }

      Then { (subject_region <=> region_inside_of_subject).should be_nil }
      Then { (subject_region <=> region_inside_of_subject_left_joint).should be_nil }
      Then { (subject_region <=> region_inside_of_subject_right_joint).should be_nil }
      Then { (subject_region <=> region_inside_to_outside_of_subject).should be_nil }
      Then { (subject_region <=> region_outside_to_inside_of_subject).should be_nil }
      
      Then{ subject_region.should <= same_as_subject_region }
      Then{ subject_region.should_not < same_as_subject_region }
      Then{ subject_region.should >= same_as_subject_region }
      Then{ subject_region.should_not > same_as_subject_region }
      
      Then{ subject_region.should < region_right_to_subject }
      Then{ subject_region.should <= region_right_to_subject }
      Then{ subject_region.should_not > region_right_to_subject }
      Then{ subject_region.should_not >= region_right_to_subject }
    end
    
    context "On + strand" do
      Given(:subject_region) { Region.new('chr1', '+', 100, 110) }
      Given(:same_as_subject_region) { Region.new('chr1', '+', 100, 110) }
      Given(:region_right_to_subject) { Region.new('chr1', '+', 113, 117) }
      Given(:region_left_to_subject) { Region.new('chr1', '+', 93, 97) }
      Given(:region_right_to_subject_joint) { Region.new('chr1', '+', 110, 117) }
      Given(:region_left_to_subject_joint) { Region.new('chr1', '+', 93, 100) }

      Given(:region_inside_of_subject) { Region.new('chr1', '+', 103, 107) }
      Given(:region_inside_of_subject_left_joint) { Region.new('chr1', '+', 100, 107) }
      Given(:region_inside_of_subject_right_joint) { Region.new('chr1', '+', 103, 110) }
      Given(:region_inside_to_outside_of_subject) { Region.new('chr1', '+', 103, 113) }
      Given(:region_outside_to_inside_of_subject) { Region.new('chr1', '+', 97, 103) }

      include_examples 'compare regions'
    end
    
    context "On - strand" do
      Given(:subject_region) { Region.new('chr1', '-', 100, 110) }
      Given(:same_as_subject_region) { Region.new('chr1', '-', 100, 110) }
      Given(:region_left_to_subject) { Region.new('chr1', '-', 113, 117) }
      Given(:region_right_to_subject) { Region.new('chr1', '-', 93, 97) }
      Given(:region_left_to_subject_joint) { Region.new('chr1', '-', 110, 117) }
      Given(:region_right_to_subject_joint) { Region.new('chr1', '-', 93, 100) }

      Given(:region_inside_of_subject) { Region.new('chr1', '-', 103, 107) }
      Given(:region_inside_of_subject_right_joint) { Region.new('chr1', '-', 100, 107) }
      Given(:region_inside_of_subject_left_joint) { Region.new('chr1', '-', 103, 110) }
      Given(:region_outside_to_inside_of_subject) { Region.new('chr1', '-', 103, 113) }
      Given(:region_inside_to_outside_of_subject) { Region.new('chr1', '-', 97, 103) }
      
      include_examples 'compare regions'
    end
  end
end