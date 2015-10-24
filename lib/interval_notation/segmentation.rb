require_relative 'sweep_line/sweep_line'

module IntervalNotation

  # Segmentation is a sorted list of non-overlapping contiguous segments (singular point can be a segment too)
  # covering whole R, i.e. (-∞; +∞).
  # Each segment is an instance of `Segment` class, i.e. it is an interval which bear some state on it.
  # State can be represented by any object. Intervals are expected to be `BasicIntervals`.
  #
  # Segmentations are treated equal if states of each point match. Thus adjacent segments can have the same state,
  # in this case they will be glued together. Such normalization allows for comparison of segmentations.
  # Note! Class provides no guarantees to store boundaries between same-state segments. They can be glued at any time.
  Segmentation = Struct.new(:segments)
  
  # Wqe have to reopen class to make a lexical scope for Segmentation::Segment
  class Segmentation
    # Helper class to store a state of a segment
    Segment = Struct.new(:interval, :state) do
      def to_s
        if state.is_a?(Set) # Set#to_s don't show any content. Quite uninformative
          set_elements = '{' + state.to_a.join(', ') + '}'
          "<#{interval}: #{set_elements}>"
        else
          "<#{interval}: #{state}>"
        end
      end
      def inspect; to_s; end
    end

    # Don't skip validation unless you're sure, that Segmentation is a correct one
    # Don't skip normalization unless you're sure, that all adjacent intervals are glued together:
    # without normalization step comparison of two segmentations will give wrong results.
    def initialize(segments, skip_validation: false, skip_normalization: false, &block)
      super(segments, &block)
      unless skip_validation
        raise 'Segmentation is not valid'  unless valid?
      end
      join_same_state_segments!  unless skip_normalization
    end

    # Check that segments don't overlap, cover whole R, and go one-after-another
    private def valid?
      return false  if segments.empty?
      return false  unless segments.all?{|segment|
        segment.is_a?(Segment)
      }
      return false  unless segments.all?{|segment|
        interval = segment.interval
        interval.respond_to?(:from) && interval.respond_to?(:include_from?) && \
        interval.respond_to?(:to) && interval.respond_to?(:include_to?)
      }
      first_interval = segments.first.interval
      last_interval = segments.last.interval
      return false  unless first_interval.from == -Float::INFINITY && last_interval.to == Float::INFINITY
      return false  unless segments.each_cons(2).all?{|segment_1, segment_2|
        segment_1.interval.to == segment_2.interval.from && (segment_1.interval.include_to? ^ segment_2.interval.include_from?)
      }
      true
    end

    # Join adjacent intervals with exactly the same state in order to compactify and normalize segmentation
    private def join_same_state_segments!
      new_segments = segments.chunk(&:state).map{|state, same_state_segments|
        intervals = same_state_segments.map(&:interval) # ToDo: optimize; don't map all segments, only the first and the last ones
        interval = BasicIntervals.interval_by_boundary_inclusion(
          intervals.first.include_from?, intervals.first.from,
          intervals.last.include_to?, intervals.last.to)
        Segment.new(interval, state)
      }
      self.segments = new_segments
    end

    def to_s; "Segmentation: #{segments}"; end
    def inspect; to_s; end

    # Make true/false segmentation based on block result. Block takes a Segment.
    # If block not specified, state is converted to boolean.
    # If block specified, its result is converted to boolean.
    def boolean_segmentation(&block)
      if block_given?
        map_state{|segment| !!block.call(segment) }
      else
        map_state{|segment| !!segment.state }
      end
    end

    # Transform segmentation into interval set according with block result.
    # Block takes a Segment and its result'd indicate whether to include corresponding interval into interval set
    def make_interval_set(&block)
      intervals = boolean_segmentation(&block).segments.select(&:state).map(&:interval)
      IntervalSet.new( intervals )
    end

    # Method `#map_state` returns a new segmentation with the same boundaries and different states
    # Block for `#map_state` takes a segment and returns new state of segment
    def map_state(&block)
      new_segments = segments.map{|segment| Segment.new(segment.interval, block.call(segment)) }
      Segmentation.new(new_segments, skip_validation: true) # here we can skip validation but not normalization
    end

    # Find a segment in which specifying point falls. It always exist, so it can't return nil. 
    def segment_covering_point(value)
      segment_index = (0...segments.size).bsearch{|segment_index| value <= segments[segment_index].interval.to }
      segment = segments[segment_index]
      if segment.interval.include_position?(value)
        segment
      else
        segments[segment_index + 1]
      end
    end
  end

end
