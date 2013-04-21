# Not tested:
# contain?
# inside?
# from_left? from_right?

require 'spec_helper.rb'
require 'semi_interval_set'

module SemiIntervalHelpers
  def all_types_of_non_empty_regions
    [:left, :right, :left_adjacent, :right_adjacent, :left_intersecting, :right_intersecting, :inside, :contact_left_inside, :contact_right_inside, :containing, :same_region]
  end
  def all_types_of_regions
    all_types_of_non_empty_regions + [:empty_region]
  end
  def arglist(*args)
    args
  end
end

shared_examples 'alignment predicate' do |meth, regions_yielding_true|
  #all_types_of_regions = [:left, :right, :left_adjacent, :right_adjacent, :left_intersecting, :right_intersecting, :inside, :containing, :same_region]
  describe "##{meth}" do
    {true => regions_yielding_true, false => all_types_of_non_empty_regions - regions_yielding_true}.each do |result, region_types|
      region_types.each do |region_type|
        specify "for #{region_type} should be #{result}" do
          region.send(meth, build(region_type)).should == result
        end
      end
    end
  end
end  

describe SemiInterval do
  extend SemiIntervalHelpers

  subject(:region){ interval(:central) }

  specify{ region.pos_start.should == 10 }
  specify{ region.pos_end.should == 20 }

  specify{ subject.should_not be_empty }
  specify{ subject.length.should == 10 }
  specify{ subject.should be_contigious }

  include_examples 'alignment predicate', :contain? , [:inside, :contact_left_inside, :contact_right_inside, :same_region]
  include_examples 'alignment predicate', :inside? , [:containing, :same_region]
  include_examples 'alignment predicate', :adjacent? , [:left_adjacent, :right_adjacent]
  include_examples 'alignment predicate', :from_left? , [:right, :right_adjacent]
  include_examples 'alignment predicate', :from_right? , [:left, :left_adjacent]
  include_examples 'alignment predicate', :intersect? , [:left_intersecting, :right_intersecting, :containing, :inside, :same_region, :contact_left_inside, :contact_right_inside]
  include_examples 'alignment predicate', :== , [:same_region]
  include_examples 'alignment predicate', :eql? , [:same_region]
  
  all_types_of_regions.each do |region_type|
    specify "intersection with #{region_type} should be commutative" do
      subject.intersection(build(region_type)).should == build(region_type).intersection(subject)
    end
    specify "uniting with #{region_type} should be commutative" do
      subject.union(build(region_type)).should == build(region_type).union(subject)
    end
  end
  
  describe '.new' do
    context 'when pos_start < pos_end' do
      specify{ SemiInterval.new(10, 20).should be_kind_of(SemiInterval) }
      specify{ SemiInterval.new(10, 20).should_not be_kind_of(EmptySemiInterval) }
    end
    context 'when pos_start == pos_end' do
      specify{ SemiInterval.new(10, 10).should be_kind_of(EmptySemiInterval) }
    end
    context 'when pos_start > pos_end' do
      specify{ expect{ SemiInterval.new(20, 10) }.to raise_error }
    end
  end
  
  describe '#intersection' do
    specify{ subject.intersection( interval(:left) ).should be_empty }
    specify{ subject.intersection( interval(:left_adjacent) ).should be_empty }
    specify{ subject.intersection( interval(:right) ).should be_empty }
    specify{ subject.intersection( interval(:right_adjacent) ).should be_empty }

    specify{ subject.intersection(interval(:left_intersecting)).should == interval(:left_intersection) }
    specify{ subject.intersection(interval(:right_intersecting)).should == interval(:right_intersection) }
    
    specify{ subject.intersection(interval(:inside)).should == interval(:inside) }
    specify{ subject.intersection(interval(:contact_left_inside)).should == interval(:contact_left_inside) }
    specify{ subject.intersection(interval(:contact_right_inside)).should == interval(:contact_right_inside) }

    specify{ subject.intersection(interval(:containing)).should == subject }
    specify{ subject.intersection(interval(:same_region)).should == subject }
  end
  
  describe '#union' do
    specify{ subject.union( interval(:left) ).should == region_set(:central, :left) }
    specify{ subject.union( interval(:right) ).should == region_set(:central, :right) }
    
    specify{ subject.union(interval(:left_adjacent)).should == build(:region_expanded_left) }
    specify{ subject.union(interval(:left_intersecting)).should == build(:region_expanded_left) }
    
    specify{ subject.union(interval(:right_adjacent)).should == build(:region_expanded_right) }
    specify{ subject.union(interval(:right_intersecting)).should == build(:region_expanded_right) }
    
    specify{ subject.union(interval(:inside)).should == subject }
    specify{ subject.union(interval(:contact_left_inside)).should == subject }
    specify{ subject.union(interval(:contact_right_inside)).should == subject }

    specify{ subject.union(interval(:containing)).should == interval(:containing) }
    specify{ subject.union(interval(:same_region)).should == subject }
  end
  
  describe '#subtract' do
    specify{ subject.subtract( interval(:left) ).should == subject }
    specify{ subject.subtract( interval(:right) ).should == subject }
    
    specify{ subject.subtract( interval(:left_adjacent) ).should == subject }
    specify{ subject.subtract(interval(:left_intersecting)).should == build(:region_cutted_left) }
    
    specify{ subject.subtract( interval(:right_adjacent) ).should == subject }
    specify{ subject.subtract(interval(:right_intersecting)).should == build(:region_cutted_right) }
    
    specify{ subject.subtract(interval(:inside)).should == region_set(:contact_left_inside, :contact_right_inside) }
    specify{ subject.subtract(interval(:contact_left_inside)).should == build(:region_cutted_left) }
    specify{ subject.subtract(interval(:contact_right_inside)).should == build(:region_cutted_right) }

    specify{ subject.subtract(interval(:containing)).should be_empty }
    specify{ subject.subtract(interval(:same_region)).should be_empty }
  end
  
  specify{ subject.hash.should == interval(:same_region).hash }
  specify{ subject.hash.should_not == build(:another_region).hash }
  
  describe '#<=>' do
    all_types_of_non_empty_regions.each do |region_type|
      region = interval(:central)
      second_region = FactoryGirl.build(region_type)
      result = region <=> second_region
      if region.from_left?( second_region )
        specify("<=> #{region_type} should be -1") { result.should == -1}
      elsif region.from_right?( second_region )
        specify("<=> #{region_type} should be 1") { result.should == 1}
      elsif region == second_region
        specify("<=> #{region_type} should be 0") { result.should == 0}
      else
        specify("<=> #{region_type} should be nil") { result.should be_nil}
      end
    end
  end
  specify{ subject.to_s.should == '[10;20)' }
  
  specify{  subject.covering_interval.should == subject }
end

describe EmptySemiInterval do
  extend SemiIntervalHelpers
  subject(:empty_region){ build(:empty_region) }
  specify{ subject.should be_empty }
  specify{ subject.length.should == 0 }
  specify{ subject.should be_contigious }
  specify{  subject.covering_interval.should == subject }
  
  specify{ subject.contain?( interval(:central) ).should be_nil }
  specify{ subject.inside?( interval(:central) ).should be_nil }
  specify{ subject.adjacent?( interval(:central) ).should be_nil }
  specify{ subject.from_left?( interval(:central) ).should be_nil }
  specify{ subject.from_right?( interval(:central) ).should be_nil }
  specify{ subject.intersect?( interval(:central) ).should be_nil }
  specify{ (subject <=> interval(:central)).should be_nil }
  specify{ subject.should_not == interval(:central) }
  specify{ subject.should == build(:same_empty_region) }
  all_types_of_regions.each do |region_type|
    specify("empty region intersected with #{region_type} should be empty"){ subject.intersection(build(region_type)).should be_empty }
    specify("empty region united with #{region_type} should be same as #{region_type}"){ subject.union(build(region_type)).should == build(region_type) }
    
    specify("intersection with #{region_type} should be commutative"){
      subject.intersection(build(region_type)).should == build(region_type).intersection(subject)
    }
    specify("uniting with #{region_type} should be commutative"){
      subject.union(build(region_type)).should == build(region_type).union(subject)
    }
    
    specify("empty region subtracted from #{region_type} should give #{region_type}"){ build(region_type).subtract(subject).should == build(region_type) }
    specify("#{region_type} subtracted from empty region should give empty region"){ subject.subtract(build(region_type)).should be_empty }
  end
  specify{ subject.to_s.should == '[empty)' }
end



describe SemiIntervalSet do
  extend SemiIntervalHelpers
  describe '.new' do
    empty_region = FactoryGirl.build(:empty_region)
    context 'with empty interval list' do
      [
      arglist(),
      arglist([]),
      arglist([],[]),
      arglist(empty_region),
      arglist(empty_region, empty_region),
      arglist([empty_region, empty_region, []], empty_region, [])
      ].each do |args|
        specify("with args: #{args.join(',')} should yield empty region"){ SemiIntervalSet.new(*args).should be_kind_of(EmptySemiInterval) }
      end
    end
    context 'with the only not null unique argument of region type' do
      region = interval(:central)
      [
      arglist(region),
      arglist([region]),
      arglist(region, region),
      arglist(region, empty_region),
      arglist([region, empty_region]),
      arglist([region, empty_region, []], empty_region,[])
      ].each do |args|
        specify("with args: #{args.join(',')} should yield SemiInterval"){ SemiIntervalSet.new(*args).should be_kind_of(SemiInterval) }
        specify("with args: #{args.join(',')} should yield original region"){ SemiIntervalSet.new(*args).should == region }
      end
    end
    context 'with the only not-null argument of SemiIntervalSet type' do
      region_set = region_set(:left, :central, :right)
      specify{ SemiIntervalSet.new(region_set).should == build(:region_set) }
      specify{ SemiIntervalSet.new(region_set, empty_region ).should == region_set }
      specify{ SemiIntervalSet.new([region_set], empty_region ).should == region_set }
    end
    context 'with several non-intersecting intervals' do
      specify 'order of arguments doesn\'t matter' do
        SemiIntervalSet.new(interval(:central), interval(:left), interval(:right)).should == SemiIntervalSet.new(interval(:left), interval(:central), interval(:right))
      end
      specify 'adjacent regions don\'t become glued together' do
        SemiIntervalSet.new(interval(:left_adjacent), interval(:central)).interval_list.should == [interval(:left_adjacent), interval(:central)]
      end
      specify 'regions goes in left-to-right direction' do
        SemiIntervalSet.new(interval(:central), interval(:left), interval(:right)).interval_list.should == [interval(:left), interval(:central), interval(:right)]
      end
    end
    context 'with several intersecting non-equal intervals' do
      specify{ expect{ SemiIntervalSet.new(interval(:central), interval(:intersecting_left)) }.to raise_error }
    end
    context 'with several adjacent intervals' do
      specify{ SemiIntervalSet.new(interval(:left_adjacent), interval(:central)).should be_kind_of(SemiIntervalSet) }
      specify{ SemiIntervalSet.new(interval(:left_adjacent), interval(:central)).interval_list.should == [interval(:left_adjacent), interval(:central)] }
    end
    context 'with several equal intervals' do
      specify 'should ignore duplicates' do
        SemiIntervalSet.new(interval(:central), interval(:left), interval(:central)).should == region_set(:central, :left)
      end
    end
  end
  
  subject{ region_set(:left, :region, :right) }
  specify{ subject.should_not be_empty }
  
  specify{ subject.should_not respond_to :length }
  specify{ subject.should_not respond_to :adjacent? }
  
  describe '#contigious?' do
    specify{ subject.should_not be_contigious }
    specify{ region_set(:central, :left_adjacent).should be_contigious }
  end
  
  # all_types_of_region_sets = [:same_region_set, :central_with_left, :central_with_right, :region_with_cutted_center]
  
  specify{ subject.should == interval(:same_region_set) }
  specify{ subject.should be_eql interval(:same_region_set) }
  specify{ subject.hash.should == interval(:same_region_set).hash }
  
  specify{ subject.should_not == build(:another_region_set_1) }
  specify{ subject.should_not == build(:another_region_set_2) }
  specify{ subject.hash.should_not == build(:another_region_set_1).hash }
  
  describe '#intersection' do
    specify{ subject.intersection(interval(:central)).should == interval(:central) }
    specify{ subject.intersection(region_set(:central, :left)).should == region_set(:central, :left) }
    specify{ subject.intersection(region_set(:contact_left_inside, :contact_right_inside)).should == region_set(:contact_left_inside, :contact_right_inside) }
    
    specify{ region_set(:central, :left).intersection(region_set(:central, :right)).should == interval(:central) }
    specify{ region_set(:central, :left).intersection(region_set(:central, :left)).should == region_set(:central, :left) }
    specify{ build(:central_with_left_adjacent).intersection(build(:central_with_left_adjacent)).should == build(:central_with_left_adjacent) }
    specify{ build(:central_with_left_adjacent).intersection(build(:containing_all)).should == build(:central_with_left_adjacent) }
    specify{ region_set(:central, :right).intersection(build(:region_expanded_left)).should == interval(:central) }
    specify{ region_set(:central, :left).intersection(interval(:left_intersecting)).should == SemiIntervalSet.new(interval(:left), interval(:left_intersection)) }
    specify{ interval(:left_intersecting).intersection(region_set(:central, :left)).should == SemiIntervalSet.new(interval(:left), interval(:left_intersection)) }
  end
  
  describe '#union' do
    { [region_set(:left, :central, :right), region_set(:left, :central, :right)] => region_set(:left, :central, :right),
      [region_set(:left, :central, :right), interval(:central)] => region_set(:left, :central, :right),
      [region_set(:left, :central, :right), region_set(:central, :left)] => region_set(:left, :central, :right),
      [region_set(:left, :central, :right), region_set(:contact_left_inside, :contact_right_inside)] => region_set(:left, :central, :right),
      
      [region_set(:left, :central), region_set(:central, :right)] => region_set(:left, :central, :right),
      [region_set(:left, :central), region_set(:left, :right)] => region_set(:left, :central, :right),
      
      [region_set(:central, :left), interval(:right)] => region_set(:left, :central, :right),
      [interval(:left), interval(:right)] => region_set(:left, :right),
      
      [region_set(:central, :right), interval(:left_intersecting)] => region_set(:region_expanded_left, :right),
      [region_set(:left_intersecting, :right_intersecting), interval(:central)] => interval(:region_expanded),
      [region_set(:contact_left_inside, :contact_right_inside), interval(:central)] => interval(:central),
      [region_set(:contact_left_inside, :contact_right_inside), interval(:inside)] => region_set(:contact_left_inside, :inside, :contact_right_inside),
      
      [region_set(:central, :right), interval(:left_adjacent)] => region_set(:left_adjacent, :central, :right),
      [region_set(:central, :left_adjacent), region_set(:central, :right)] => region_set(:left_adjacent, :central, :right)      
    }.each do |(first_arg, second_arg), result|
      specify{ first_arg.union(second_arg).should == result }
      specify{ second_arg.union(first_arg).should == result }
      specify{ (first_arg + second_arg).should == result }
      specify{ (second_arg + first_arg).should == result }
    end
    
  end
  
  describe '#subtract' do
    specify{ subject.subtract(subject).should be_empty }
    specify{ subject.subtract(build(:containing_all)).should be_empty }
    specify{ subject.subtract(build(:another_region)).should == subject }
    specify{ subject.subtract(build(:far_region_set)).should == subject }
    specify{ subject.subtract(interval(:right)).should == region_set(:central, :left) }
    specify{ subject.subtract(interval(:right_adjacent)).should == region_set(:central, :left) }
    specify{ subject.subtract(interval(:central)).should == build(:left_with_right) }
    specify{ subject.subtract(interval(:containing)).should == build(:left_with_right) }
    specify{ subject.subtract(interval(:right_intersecting)).should == build(:central_shortened_from_right_with_left) }
    specify{ interval(:central).subtract(build(:region_set)).should be_empty }
    specify{ interval(:central).subtract(build(:far_region_set)).should == interval(:central) }
    specify{ interval(:central).subtract(region_set(:contact_left_inside, :contact_right_inside)).should == interval(:inside) }
    specify{ interval(:central).subtract(build(:region_with_cutted_center_expanded_left)).should == interval(:inside) }
    specify{ interval(:central).subtract(build(:far_region_with_inside)).should == region_set(:contact_left_inside, :contact_right_inside) }
  end
  
  
  describe '#intersect?' do
    specify{ subject.intersect?(interval(:central)).should == true }
    specify{ interval(:central).intersect?(subject).should == true }
    specify{ region_set(:region, :left_adjacent).intersect?(interval(:central)).should == true }
    specify{ region_set(:region, :left_adjacent).intersect?(interval(:left)).should == true }
    specify{ region_set(:region, :left).intersect?(region_set(:central, :right)).should == true }
    specify{ region_set(:region, :left).intersect?(region_set(:central, :left)).should == true }
    specify{ region_set(:region, :left_adjacent).intersect?(interval(:right_intersecting)).should == true }
   # specify{ region_set(:central, :right).intersect?(build(:left_intersecting_with_fars)).should == true }
    specify{ interval(:right_intersecting).intersect?(build(:central_with_left_adjacent)).should == true }
    specify{ region_set(:region, :left).intersect?(build(:right_with_far_region)).should == false }
  end

  
  describe '#unite_adjacent' do
    specify{ region_set(:left_adjacent, :central, :right).unite_adjacent.should == region_set(:region_expanded_left, :right) }
    specify{ (region_set(:contact_left_inside, :contact_right_inside) + interval(:inside)).should_not == region_set(:central) }
    specify{ (region_set(:contact_left_inside, :contact_right_inside) + interval(:inside)).unite_adjacent.should == region_set(:central) }
  end
  
  describe '#==' do
    specify{ region_set(:central).should == interval(:central) }
    specify{ region_set(:left, :central, :right).should == region_set(:left, :central, :right) }
    specify{ region_set(:left_adjacent, :central).should == region_set(:central, :left_adjacent) }
    specify{ region_set(:left_adjacent, :central, :right_adjacent).should_not == region_set(:left, :central, :right) }
    specify{ region_set(:left_adjacent, :central, :right_adjacent).should_not == interval(:region_expanded) }
    specify{ region_set(:left_adjacent, :central).should_not == interval(:region_expanded_left) }
  end
  
  specify{ subject.covering_interval.should == build(:region_expanded) }
  specify{ subject.to_s.should == "[3;8)U[10;20)U[25;30)" }
end