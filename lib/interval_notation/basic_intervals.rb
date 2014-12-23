require_relative 'error'

module IntervalNotation
  BoundaryPoint = Struct.new(:value, :included, :opening, :interval_index, :interval_boundary)

  class OpenOpenInterval
    attr_reader :from, :to
    def initialize(from, to)
      raise Error, "Interval (#{from};#{to}) can't be created"  unless from < to
      @from = from
      @to = to
    end
    def length; to - from; end
    def to_s; "(#{from};#{to})"; end
    def inspect; to_s; end
    def include_from?; false; end
    def include_to?; false; end
    def singular_point?; false; end
    def include_position?(value); from < value && value < to; end
    def hash; [@from, @to, :open, :open].hash; end;
    def eql?(other); other.class.equal?(self.class) && from == other.from && to == other.to; end
    def ==(other); other.is_a?(OpenOpenInterval) && from == other.from && to == other.to; end
    def interval_boundaries(interval_index)
      [ BoundaryPoint.new(from, false, true, interval_index, true),
        BoundaryPoint.new(to, false, false, interval_index, true) ]
    end
  end

  class OpenClosedInterval
    attr_reader :from, :to
    def initialize(from, to)
      raise Error, "Interval (#{from};#{to}] can't be created"  unless from < to
      raise Error, "Infinite boundary should be open" unless to.to_f.finite?
      @from = from
      @to = to
    end
    def length; to - from; end
    def to_s; "(#{from};#{to}]"; end
    def inspect; to_s; end
    def include_from?; false; end
    def include_to?; true; end
    def singular_point?; false; end
    def include_position?(value); from < value && value <= to; end
    def hash; [@from, @to, :open, :closed].hash; end;
    def eql?(other); other.class.equal?(self.class) && from == other.from && to == other.to; end
    def ==(other); other.is_a?(OpenClosedInterval) && from == other.from && to == other.to; end
    def interval_boundaries(interval_index)
      [ BoundaryPoint.new(from, false, true, interval_index, true),
        BoundaryPoint.new(to, true, false, interval_index, true) ]
    end
  end

  class ClosedOpenInterval
    attr_reader :from, :to
    def initialize(from, to)
      raise Error, "Interval [#{from};#{to}) can't be created"  unless from < to
      raise Error, "Infinite boundary should be open" unless from.to_f.finite?
      @from = from
      @to = to
    end
    def length; to - from; end
    def to_s; "[#{from};#{to})"; end
    def inspect; to_s; end
    def include_from?; true; end
    def include_to?; false; end
    def singular_point?; false; end
    def include_position?(value); from <= value && value < to; end
    def hash; [@from, @to, :closed, :open].hash; end;
    def eql?(other); other.class.equal?(self.class) && from == other.from && to == other.to; end
    def ==(other); other.is_a?(ClosedOpenInterval) && from == other.from && to == other.to; end
    def interval_boundaries(interval_index)
      [ BoundaryPoint.new(from, true, true, interval_index, true),
        BoundaryPoint.new(to, false, false, interval_index, true) ]
    end
  end

  class ClosedClosedInterval
    attr_reader :from, :to
    def initialize(from, to)
      raise Error, "Interval [#{from};#{to}] can't be created"  unless from < to
      raise Error, "Infinite boundary should be open" unless from.to_f.finite? && to.to_f.finite?
      @from = from
      @to = to
    end
    def length; to - from; end
    def to_s; "[#{from};#{to}]"; end
    def inspect; to_s; end
    def include_from?; true; end
    def include_to?; true; end
    def singular_point?; false; end
    def include_position?(value); from <= value && value <= to; end
    def hash; [@from, @to, :closed, :closed].hash; end;
    def eql?(other); other.class.equal?(self.class) && from == other.from && to == other.to; end
    def ==(other); other.is_a?(ClosedClosedInterval) && from == other.from && to == other.to; end
    def interval_boundaries(interval_index)
      [ BoundaryPoint.new(from, true, true, interval_index, true),
        BoundaryPoint.new(to, true, false, interval_index, true) ]
    end
  end

  class Point
    attr_reader :value
    protected :value
    def initialize(value)
      raise Error, "Point can't represent an infinity"  unless value.to_f.finite?
      @value = value
    end
    def from; value; end
    def to; value; end
    def length; 0; end
    def to_s; "{#{@value}}"; end
    def inspect; to_s; end
    def include_from?; true; end
    def include_to?; true; end
    def singular_point?; true; end
    def include_position?(val); value == val; end
    def hash; @value.hash; end;
    def eql?(other); other.class.equal?(self.class) && value == other.value; end
    def ==(other); other.is_a?(Point) && value == other.value; end
    def interval_boundaries(interval_index)
      BoundaryPoint.new(from, true, nil, interval_index, false)
    end
  end
end
