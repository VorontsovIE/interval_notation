require 'spec_helper'
require 'semi_interval_set'

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
    factory(:same_region) { region 10..20 }
    
    # helper factories
    factory(:another_region) { region 110..120 }
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
    
    factory(:central_with_left) { with_interval_list :left, :region }
    factory(:central_with_left_adjacent) { with_interval_list :left_adjacent, :region }
    factory(:central_shortened_from_right_with_left) { with_interval_list :left, :central_shortened_from_right }
    factory(:left_with_right) { with_interval_list :left, :right }
    factory(:central_expanded_left_with_right) { with_interval_list :region_expanded_left, :right }
    factory(:central_with_right) { with_interval_list :region, :right }
    factory(:region_with_cutted_center) { with_interval_list :contact_left_inside, :contact_right_inside }
    factory(:region_with_cutted_center_expanded_left) { with_interval_list :left_intersecting, :contact_right_inside }
    factory(:long_region_with_cutted_center) { with_interval_list :left_intersecting, :right_intersecting }
    factory(:same_region_set){ with_interval_list :left, :region, :right }
    factory(:another_region_set_1){ with_interval_list :region, :right }
    factory(:another_region_set_2){ with_interval_list :containing, :another_region }
    factory(:right_with_far_region) { with_interval_list :right, :another_region }
    factory(:far_region_set) { with_interval_list :another_region, :another_region_2 }
    factory(:far_region_with_inside) { with_interval_list :another_region, :inside }
    #factory(:left_intersecting_with_fars) { with_interval :left_intersecting, :another_region, :far_left }
  end
end