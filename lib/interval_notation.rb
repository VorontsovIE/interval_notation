require 'interval_notation/version'

module IntervalNotation
  module PrivateZone
  end
end

require 'interval_notation/basic_intervals'
require 'interval_notation/interval_set'

module IntervalNotation
  private_constant :PrivateZone

  # make private constants accessible
  open_open_interval_class = const_get(:PrivateZone)::OpenOpenInterval
  open_closed_interval_class = const_get(:PrivateZone)::OpenClosedInterval
  closed_open_interval_class = const_get(:PrivateZone)::ClosedOpenInterval
  closed_closed_interval_class = const_get(:PrivateZone)::ClosedClosedInterval
  interval_set_class = const_get(:PrivateZone)::IntervalSet
  point_class = const_get(:PrivateZone)::Point


  R = interval_set_class.new( [open_open_interval_class.new(-Float::INFINITY, Float::INFINITY)] )
  Empty = interval_set_class.new([])

  define_method :oo do |from, to|
    interval_set_class.new( [open_open_interval_class.new(from, to)] )
  end

  define_method :co do |from, to|
    interval_set_class.new( [closed_open_interval_class.new(from, to)] )
  end

  define_method :oc do |from, to|
    interval_set_class.new( [open_closed_interval_class.new(from, to)] )
  end

  define_method :cc do |from, to|
    interval_set_class.new( [closed_closed_interval_class.new(from, to)] )
  end

  define_method :pt do |value|
    interval_set_class.new( [point_class.new(value)] )
  end

  define_method :lt do |value|
    interval_set_class.new( [open_open_interval_class.new(-Float::INFINITY, value)] )
  end

  define_method :le do |value|
    interval_set_class.new( [open_closed_interval_class.new(-Float::INFINITY, value)] )
  end

  define_method :gt do |value|
    interval_set_class.new( [open_open_interval_class.new(value, Float::INFINITY)] )
  end

  define_method :ge do |value|
    interval_set_class.new( [closed_open_interval_class.new(value, Float::INFINITY)] )
  end

  module_function :oo, :co, :oc, :cc, :pt, :lt, :le, :gt, :ge
end
