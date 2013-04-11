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
  Given(:region_inside) { Region.new('chr1', '+', 103, 107) }
  Given(:region_inside_extend_to_end) { Region.new('chr1', '+', 103, 110) }
  Given(:region_inside_extend_to_start) { Region.new('chr1', '+', 100, 103) }

  Given(:region_on_another_strand) { Region.new('chr1', '-', 103, 107) }
  Given(:region_on_another_chromosome) { Region.new('chr2', '+', 103, 107) }

  Given(:region_from_inside_to_outside_after_end) { Region.new('chr1', '+', 103, 113) }
  Given(:region_from_outside_before_start_to_inside) { Region.new('chr1', '+', 97, 103) }

  Given(:region_containing) { Region.new('chr1', '+', 97, 113) }

  Given(:region_outside_left) { Region.new('chr1', '+', 97, 99) }
  Given(:region_outside_right) { Region.new('chr1', '+', 113, 117) }
  Given(:region_outside_extend_from_end) { Region.new('chr1', '+', 110, 113) }
  Given(:region_outside_extend_to_start) { Region.new('chr1', '+', 97, 100) }
  
  #Given(:empty_region) { Region.new('chr1', '+', 103, 103) }

  describe '#intersection' do
    Then{ region.intersection(region).should == region }
    Then{ region.intersection(region_inside).should == region_inside }
    Then{ region.intersection(region_inside_extend_to_end).should == region_inside_extend_to_end }
    Then{ region.intersection(region_inside_extend_to_start).should == region_inside_extend_to_start }

    Then{ region.intersection(region_on_another_strand).should == nil }
    Then{ region.intersection(region_on_another_chromosome).should == nil }

    Then{ region.intersection(region_from_inside_to_outside_after_end).should == Region.new('chr1', '+', 103, 110) }
    Then{ region.intersection(region_from_outside_before_start_to_inside).should == Region.new('chr1', '+', 100, 103) }

    Then{ region.intersection(region_containing).should == region }

    Then{ region.intersection(region_outside_left).should == nil }
    Then{ region.intersection(region_outside_right).should == nil }
    Then{ region.intersection(region_outside_extend_from_end).should == nil }
    Then{ region.intersection(region_outside_extend_to_start).should == nil }
  end
end