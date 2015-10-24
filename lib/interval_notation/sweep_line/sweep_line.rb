require_relative '../segmentation'

module IntervalNotation
  # SweepLine is an internal helper module for combining interval sets using sweep line.
  # It starts moving from -∞ to +∞ and keep which intervals are crossed by sweep line in trace-state variable.
  # State object have methods which recalculate state when sweep line meets a group of boundary points
  # and a method to convolve state underlying representation into surface state value.
  # E.g. `Union` trace state can store information about which intervals are intersected by a sweep line,
  # but on surface one knows only whether it intersects any interval.
  #
  # Boundary points for state recalculation are grouped by the same coordinate. As sweep lines goes left-to-right,
  # initial state is a state at -∞.
  # See `TraceState` module for an examples of trace-states.
  #
  # Principially sweep line method helps to effectively recalculate number of crossed intervals without rechecking
  # all intervals each time, and dramatically reduces speed of operations on large number of intervals.
  #
  # Usage example:
  #   SweepLine.make_interval_set([interval_1, interval_2, interval_3], SweepLine::TraceState::Union.initial_state(3))
  #
  module SweepLine
    # Make segmentation by state of a list of interval sets.
    # Accepts a list of pairs (interval, tag)
    def self.make_segmentation(indexed_interval_sets, initial_state)
      points = interval_boundaries(indexed_interval_sets)
      segmentation_by_boundary_points(points, initial_state).map_state{|segment|
        segment.state.state_convolution
      }
    end

    # Make segmentation by state of a list of interval sets.
    # Accepts a list of intervals without tags.
    def self.make_interval_set(interval_sets, initial_state)
      make_segmentation(interval_sets.each_with_index, initial_state).make_interval_set
    end

    # Make tagging segmentation of interval sets.
    # Each segment's state in a resulting segmentation is a set of tags lying against a segment.
    def self.make_tagging(indexed_interval_sets)
      make_segmentation(indexed_interval_sets, SweepLine::TraceState::SingleTagging.initial_state)
    end

    # Make multi-tagging segmentation of interval sets. Multi-tagging means that segment store 
    # not only tag but number of times this tag was met.
    # Each segment's state in a resulting segmentation is a hash {tag => count} for tags lying against a segment.
    def self.make_multitagging(indexed_interval_sets)
      make_segmentation(indexed_interval_sets, SweepLine::TraceState::MultiTagging.initial_state)
    end

    # Extracts interval boundaries marked by interval indices or tags
    # Accepts a list of pairs (interval, tag)
    def self.interval_boundaries(tagged_interval_sets)
      tagged_interval_sets.flat_map{|interval_set, interval_set_tag|
        interval_set.intervals.flat_map{|interval|
          interval.interval_boundaries(interval_set_tag)
        }
      }
    end

    # Make a segmentation using sweep line along boundary points.
    def self.segmentation_by_boundary_points(boundary_points, initial_state)
      if boundary_points.empty?
        segment = Segmentation::Segment.new(BasicIntervals::OpenOpenInterval.new(-Float::INFINITY, Float::INFINITY), initial_state)
        return Segmentation.new([segment])
      end

      point_chunks = boundary_points.sort_by(&:value).chunk(&:value).to_a
      state = initial_state

      # Process minus-infinity points which can change initial state
      if point_chunks.first.first == -Float::INFINITY
        point_value, points_at_minus_infinity = point_chunks.shift
        state = state.state_after_point(points_at_minus_infinity)
      end

      # Remove plus-infinity points as they can change state but this won't be reflected by any interval
      if point_chunks.last.first == Float::INFINITY
        point_value, points_at_plus_infinity = point_chunks.pop
      end

      prev_point_value = -Float::INFINITY
      segments = []
      # We removed points at plus or minus infinity so now we process inner points
      point_chunks.each do |point_value, points_on_place|
        segments << Segmentation::Segment.new(BasicIntervals::OpenOpenInterval.new(prev_point_value, point_value), state)
        segments << Segmentation::Segment.new(BasicIntervals::Point.new(point_value), state.state_at_point(points_on_place))
        state = state.state_after_point(points_on_place)
        prev_point_value = point_value
      end

      # add fictive segment up to plus-infinity point (may be fictive)
      segments << Segmentation::Segment.new(BasicIntervals::OpenOpenInterval.new(prev_point_value, Float::INFINITY), state)
      Segmentation.new(segments, skip_validation: true) # here we can skip validation but not normalization
    end

  end
end
