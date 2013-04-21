require 'spec_helper'
require 'semi_interval_set'

def empty_interval
  EmptySemiInterval.new
end

def with_interval_list(*region_names)
  interval_list( region_names.map{|region_name| FactoryGirl.build(region_name)} )
end

def region_set(*region_names)
  SemiIntervalSet.new( region_names.map{|interval_name| interval(interval_name)} )
end

def interval(interval_name)
  FactoryGirl.build(interval_name)
end

FactoryGirl.define do
  factory :empty_region, class: EmptySemiInterval do
    initialize_with{ new() }
  end
  factory :same_empty_region, class: EmptySemiInterval do
    initialize_with{ new() }
  end

  factory :region, aliases: [:central], class: SemiInterval do
    initialize_with{ SemiInterval.new(region.begin, region.end) }

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
    factory(:containing_all) { region 1..100 }
    factory(:same_region, aliases: [:same_as_central]) { region 10..20 }

    # helper factories
    factory(:another_region, aliases: [:far_region, :far_right]) { region 110..120 }
    factory(:another_region_2) { region 120..220 }
    factory(:far_left) { region (-100)..(-90) }
    factory(:left_intersection) { region 10..13 }
    factory(:right_intersection) { region 17..20 }
    factory(:central_shortened_from_right) { region 10..17 }
    factory(:region_expanded_left) { region 3..20 }
    factory(:region_expanded_right) { region 10..30 }
    factory(:region_expanded) { region 3..30 }

    factory(:region_cutted_left) { region 13..20 }
    factory(:region_cutted_right) { region 10..17 }
  end

  factory :region_set, class: SemiIntervalSet do
    initialize_with{ new(*interval_list) }
    with_interval_list :left, :central, :right

    factory(:same_region_set){ with_interval_list :left, :region, :right }
    factory(:another_region_set_1){ with_interval_list :region, :right }
    factory(:another_region_set_2){ with_interval_list :containing, :far_region }
  end
end