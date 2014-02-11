require_relative '../spec_helper'
require_relative '../../lib/intervals/interval_algebra'

def empty_interval
  IntervalAlgebra::EmptySemiInterval.new
end

def with_interval_list(*region_names)
  interval_list( region_names.map{|region_name| FactoryGirl.build(region_name)} )
end

def region_set(*region_names)
  IntervalAlgebra::SemiIntervalSet.new( region_names.map{|interval_name| interval(interval_name)} )
end

def interval(interval_name)
  FactoryGirl.build(interval_name)
end

FactoryGirl.define do
  factory :central, class: IntervalAlgebra::SemiInterval do
    initialize_with{ IntervalAlgebra::SemiInterval.new(region.begin, region.end) }

    region 10..20
    factory(:left) { region 3..8 }
    factory(:right) { region 25..30 }
    factory(:left_adjacent) { region 3..10 }
    factory(:right_adjacent) { region 20..30 }
    factory(:left_intersecting) { region 3..13 }
    factory(:right_intersecting) { region 17..30 }
    factory(:inside) { region 13..17 }
    factory(:contact_left_inside) { region 10..13 }
    factory(:contact_right_inside) { region 17..20 }
    factory(:containing) { region 9..23 }
    factory(:same_region, aliases: [:same_as_central]) { region 10..20 }

    factory(:whole_numeric_axis) { region (-Float::INFINITY)..(Float::INFINITY) }
    factory(:infinite_to_left) { region (-Float::INFINITY)..10 }
    factory(:infinite_to_left_from_left_region) { region (-Float::INFINITY)..3 }
    factory(:infinite_to_right_from_left_boundary) { region 10..(Float::INFINITY) }
    factory(:infinite_to_right) { region 20..(Float::INFINITY) }

    # helper factories
    factory(:far_right, aliases: [:far_region]) { region 110..120 }
    factory(:far_left) { region (-100)..(-90) }
    factory(:left_intersection) { region 10..13 }
    factory(:right_intersection) { region 17..20 }
    factory(:region_expanded_left) { region 3..20 }
    factory(:region_expanded_right) { region 10..30 }
    factory(:region_expanded) { region 3..30 }

    factory(:region_cutted_left) { region 13..20 }
    factory(:region_cutted_right) { region 10..17 }
  end
end
