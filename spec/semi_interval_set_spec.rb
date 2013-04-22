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

  # specs for precedence
  specify{ (interval(:central) & interval(:central) | interval(:left)).should == (interval(:central) & interval(:central)) | interval(:left)}
  specify{ (interval(:central) & interval(:central) | interval(:left)).should_not == interval(:central) & (interval(:central) | interval(:left)) }
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
        SemiIntervalSet.new(interval(:central), interval(:left), interval(:central)).should == region_set(:left, :central)
      end
    end
  end

  subject{ region_set(:left, :region, :right) }
  specify{ subject.should_not be_empty }

  specify{ subject.should_not respond_to :length }
  specify{ subject.should_not respond_to :adjacent? }

  describe '#contigious?' do
    specify{ region_set(:left, :central, :right).should_not be_contigious }
    specify{ region_set(:left_adjacent, :central).should be_contigious }
    specify{ region_set(:left_adjacent, :central, :right_adjacent).should be_contigious }
    specify{ region_set(:left_adjacent, :central, :right).should_not be_contigious }
  end

  specify{ region_set(:left, :central, :right).should == region_set(:left, :central, :right) }
  specify{ region_set(:left, :central, :right).should be_eql region_set(:left, :central, :right) }

  specify{ region_set(:left, :central, :right).should_not == region_set(:left, :central) }
  specify{ region_set(:left, :central, :right).should_not == region_set(:region_expanded, :far_region) }

  specify{ subject.covering_interval.should == build(:region_expanded) }
  specify{ subject.to_s.should == "[3;8)U[10;20)U[25;30)" }
end

########################

describe 'Regions and region sets' do
  describe '#intersection' do
    {
      [empty_interval, interval(:central)] => empty_interval,
      [empty_interval, region_set(:left, :central, :right)] => empty_interval,
      [empty_interval, empty_interval] => empty_interval,

      [interval(:central), interval(:left)] => empty_interval,
      [interval(:central), interval(:left_adjacent)] => empty_interval,
      [interval(:central), interval(:right)] => empty_interval,
      [interval(:central), interval(:right_adjacent)] => empty_interval,
      [interval(:central), interval(:left_intersecting)] => interval(:left_intersection),
      [interval(:central), interval(:right_intersecting)] => interval(:right_intersection),
      [interval(:central), interval(:inside)] => interval(:inside),
      [interval(:central), interval(:contact_left_inside)] => interval(:contact_left_inside),
      [interval(:central), interval(:contact_right_inside)] => interval(:contact_right_inside),
      [interval(:central), interval(:containing)] => interval(:central),
      [interval(:central), interval(:central)] => interval(:central),
      [interval(:central), interval(:same_as_central)] => interval(:central),

      [region_set(:left, :central, :right), interval(:central)] => interval(:central),
      [region_set(:left, :central, :right), region_set(:left, :central)] => region_set(:left, :central),
      [region_set(:left, :central), region_set(:left, :central)] => region_set(:left, :central),
      [region_set(:left, :central, :right), region_set(:contact_left_inside, :contact_right_inside)] => region_set(:contact_left_inside, :contact_right_inside),
      [region_set(:left, :central), region_set(:central, :right)] => interval(:central),
      [region_set(:left_adjacent, :central), region_set(:left_adjacent, :central)] => region_set(:left_adjacent, :central),
      [region_set(:left_adjacent, :central), interval(:containing_all)] => region_set(:left_adjacent, :central),
      [region_set(:central, :right), interval(:region_expanded_left)] => interval(:central),
      [interval(:left_intersecting), region_set(:left, :central)] => region_set(:left, :left_intersection)
    }.each do |(first_arg, second_arg), result|
      specify("#{first_arg} intersection #{second_arg} should be #{result}"){ first_arg.intersection(second_arg).should == result }
      specify("#{second_arg} intersection #{first_arg} should be #{result}"){ second_arg.intersection(first_arg).should == result }
      specify("#{first_arg} & #{second_arg} should be #{result}"){ (first_arg & second_arg).should == result }
      specify("#{second_arg} & #{first_arg} should be #{result}"){ (second_arg & first_arg).should == result }
      if result == empty_interval
        specify("#{first_arg} intersect? #{second_arg} should be false"){ first_arg.intersect?(second_arg).should be_false }
        specify("#{second_arg} intersect? #{first_arg} should be false"){ second_arg.intersect?(first_arg).should be_false }
      else
        specify("#{first_arg} intersect? #{second_arg} should be true"){ first_arg.intersect?(second_arg).should be_true }
        specify("#{second_arg} intersect? #{first_arg} should be true"){ second_arg.intersect?(first_arg).should be_true }
      end
    end
  end

  describe '#union' do
    { [empty_interval, interval(:central)] => interval(:central),
      [empty_interval, region_set(:left, :central, :right)] => region_set(:left, :central, :right),
      [empty_interval, empty_interval] => empty_interval,

      [interval(:central), interval(:left)] => region_set(:left, :central),
      [interval(:central), interval(:right)] => region_set(:central, :right),
      [interval(:central), interval(:left_adjacent)] => interval(:region_expanded_left),
      [interval(:central), interval(:left_intersecting)] => interval(:region_expanded_left),
      [interval(:central), interval(:right_adjacent)] => interval(:region_expanded_right),
      [interval(:central), interval(:right_intersecting)] => interval(:region_expanded_right),
      [interval(:central), interval(:inside)] => interval(:central),
      [interval(:central), interval(:contact_left_inside)] => interval(:central),
      [interval(:central), interval(:contact_right_inside)] => interval(:central),
      [interval(:central), interval(:containing)] => interval(:containing),
      [interval(:central), interval(:central)] => interval(:central),
      [interval(:central), interval(:central)] => interval(:same_as_central),

      [region_set(:left, :central, :right), empty_interval] => region_set(:left, :central, :right),
      [region_set(:left, :central, :right), region_set(:left, :central, :right)] => region_set(:left, :central, :right),
      [region_set(:left, :central, :right), interval(:central)] => region_set(:left, :central, :right),
      [region_set(:left, :central, :right), region_set(:left, :central)] => region_set(:left, :central, :right),
      [region_set(:left, :central, :right), region_set(:contact_left_inside, :contact_right_inside)] => region_set(:left, :central, :right),

      [region_set(:left, :central), region_set(:central, :right)] => region_set(:left, :central, :right),
      [region_set(:left, :central), region_set(:left, :right)] => region_set(:left, :central, :right),

      [region_set(:left, :central), interval(:right)] => region_set(:left, :central, :right),
      [region_set(:left_adjacent, :central), region_set(:left_adjacent, :central)] => region_set(:left_adjacent, :central),
      [interval(:left), interval(:right)] => region_set(:left, :right),

      [region_set(:central, :right), interval(:left_intersecting)] => region_set(:region_expanded_left, :right),
      [region_set(:left_intersecting, :right_intersecting), interval(:central)] => interval(:region_expanded),
      [region_set(:contact_left_inside, :contact_right_inside), interval(:central)] => interval(:central),
      [region_set(:contact_left_inside, :contact_right_inside), interval(:inside)] => region_set(:contact_left_inside, :inside, :contact_right_inside),

      [region_set(:central, :right), interval(:left_adjacent)] => region_set(:left_adjacent, :central, :right),
      [region_set(:left_adjacent, :central), region_set(:central, :right)] => region_set(:left_adjacent, :central, :right)
    }.each do |(first_arg, second_arg), result|
      specify("#{first_arg} union #{second_arg} should be #{result}"){ first_arg.union(second_arg).should == result }
      specify("#{second_arg} union #{first_arg} should be #{result}"){ second_arg.union(first_arg).should == result }
      specify("#{first_arg} | #{second_arg} should be #{result}"){ (first_arg | second_arg).should == result }
      specify("#{second_arg} | #{first_arg} should be #{result}"){ (second_arg | first_arg).should == result }
    end

  end

  describe '#subtract' do
    { [empty_interval, empty_interval] => empty_interval,
      [empty_interval, interval(:central)] => empty_interval,
      [empty_interval, region_set(:left, :central, :right)] => empty_interval,
      [interval(:central), empty_interval] => interval(:central),
      [region_set(:left, :central, :right), empty_interval] => region_set(:left, :central, :right),

      [interval(:central), interval(:central)] => empty_interval,
      [interval(:central), interval(:same_as_central)] => empty_interval,
      [interval(:central), interval(:containing)] => empty_interval,
      [interval(:central), interval(:left)] => interval(:central),
      [interval(:central), interval(:right)] => interval(:central),
      [interval(:central), interval(:left_adjacent)] => interval(:central),
      [interval(:central), interval(:right_adjacent)] => interval(:central),
      [interval(:central), interval(:left_intersecting)] => interval(:region_cutted_left),
      [interval(:central), interval(:right_intersecting)] => interval(:region_cutted_right),
      [interval(:central), interval(:far_region)] => interval(:central),
      [interval(:central), interval(:inside)] => region_set(:contact_left_inside, :contact_right_inside),
      [interval(:central), interval(:contact_left_inside)] => interval(:region_cutted_left),
      [interval(:central), interval(:contact_right_inside)] => interval(:region_cutted_right),

      [interval(:central), region_set(:left, :right, :central)] => empty_interval,
      [interval(:central), region_set(:far_region, :containing)] => empty_interval,
      [interval(:central), region_set(:far_left, :far_right)] => interval(:central),
      [interval(:central), region_set(:inside, :far_region)] => region_set(:contact_left_inside, :contact_right_inside),
      [interval(:central), region_set(:contact_left_inside, :contact_right_inside)] => interval(:inside),
      [interval(:central), region_set(:left_intersecting, :contact_right_inside)] => interval(:inside),

      [region_set(:left, :central, :right), region_set(:left, :central, :right)] => empty_interval,
      [region_set(:left, :central, :right), interval(:containing_all)] => empty_interval,
      [region_set(:left, :central, :right), interval(:far_region)] => region_set(:left, :central, :right),
      [region_set(:left, :central, :right), region_set(:far_left, :far_right)] => region_set(:left, :central, :right),
      [region_set(:left, :central, :right), interval(:right)] => region_set(:left, :central),
      [region_set(:left, :central, :right), interval(:right_adjacent)] => region_set(:left, :central),
      [region_set(:left, :central, :right), interval(:central)] => region_set(:left, :right),
      [region_set(:left, :central, :right), interval(:containing)] => region_set(:left, :right),
      [region_set(:left, :central, :right), interval(:right_intersecting)] => region_set(:left, :central_shortened_from_right),
      [region_set(:left, :central, :right), interval(:inside)] => region_set(:left, :contact_left_inside, :contact_right_inside, :right),
      [region_set(:left, :central, :right), region_set(:contact_left_inside, :contact_right_inside)] => region_set(:left, :inside, :right)
    }.each do |(first_arg, second_arg), result|
      specify("#{first_arg} subtract #{second_arg} should be #{result}"){ first_arg.subtract(second_arg).should == result }
      specify("#{first_arg} - #{second_arg} should be #{result}"){ (first_arg - second_arg).should == result }
    end
  end


  describe '#complement' do
    { empty_interval => SemiInterval.new(-Float::INFINITY, Float::INFINITY),
      interval(:central) => SemiIntervalSet.new( SemiInterval.new(-Float::INFINITY, 10), SemiInterval.new(20, Float::INFINITY) ),
      region_set(:left, :right) => SemiIntervalSet.new( SemiInterval.new(-Float::INFINITY, 3), SemiInterval.new(8, 25), SemiInterval.new(30, Float::INFINITY) ),
      SemiInterval.new(-Float::INFINITY, 10) => SemiInterval.new(10, Float::INFINITY)
    }.each do |region, result|
      specify("#{region} complement should be #{result}"){ region.complement.should == result }
      specify("#{result} complement should be #{region}"){ result.complement.should == region }
      specify("~#{region} should be #{result}"){ (~region).should == result }
      specify("~#{result} should be #{region}"){ (~result).should == region }
    end
  end

  describe '#unite_adjacent' do
    specify{ empty_interval.unite_adjacent.should == empty_interval }
    specify{ interval(:central).unite_adjacent.should == interval(:central) }
    specify{ region_set(:left, :central, :right).unite_adjacent.should == region_set(:left, :central, :right) }
    specify{ region_set(:left_adjacent, :central, :right).unite_adjacent.should == region_set(:region_expanded_left, :right) }
    specify{ (region_set(:left_adjacent, :right_adjacent) | interval(:central)).should_not == region_set(:region_expanded) }
    specify{ (region_set(:left_adjacent, :right_adjacent) | interval(:central)).unite_adjacent.should == region_set(:region_expanded) }
  end

  describe '#==' do
    { [interval(:central), interval(:central)] => true,
      [region_set(:left, :central, :right), region_set(:left, :central, :right)] => true,
      [region_set(:left_adjacent, :central, :right_adjacent), region_set(:left_adjacent, :central, :right_adjacent)] => true,
      [empty_interval, empty_interval] => true,

      [interval(:central), interval(:right)] => false,
      [interval(:central), empty_interval] => false,
      [interval(:central), region_set(:left, :central)] => false,
      [interval(:central), region_set(:left, :right)] => false,
      [interval(:central), interval(:inside)] => false,
      [interval(:central), interval(:containing)] => false,

      [region_set(:left, :central, :right), region_set(:left, :right)] => false,
      [region_set(:left, :central, :right), region_set(:far_left, :far_right)] => false,
      [region_set(:left, :central, :right), empty_interval] => false,
      [region_set(:left_adjacent, :central, :right_adjacent), interval(:region_expanded)] => false,
      [region_set(:left_adjacent, :central), interval(:region_expanded_left)] => false,
      [region_set(:left_adjacent, :central, :right_adjacent), region_set(:left, :central, :right)] => false
    }.each do |(first_region, second_region), result|
      specify("#{first_region} == #{second_region} should be #{result}") { (first_region == second_region).should == result }
      specify("#{second_region} == #{first_region} should be #{result}") { (second_region == first_region).should == result }
      specify("#{first_region} eql? #{second_region} should be #{result}") { (first_region.eql? second_region).should == result }
      specify("#{second_region} eql? #{first_region} should be #{result}") { (second_region.eql? first_region).should == result }
      if result
        specify("#{first_region}.hash should be equal to #{second_region}.hash"){ first_region.hash.should == second_region.hash }
      end
    end
  end

end