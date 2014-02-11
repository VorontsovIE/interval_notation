require_relative 'semi_interval'

module IntervalAlgebra
  class EmptySemiInterval < SemiInterval
    def self.new
      @empty_semi_interval ||= begin
        obj = allocate
        obj.send :initialize
        obj
      end
    end

    def initialize; end
    def empty?; true; end
    def length; 0; end
    def intersection(other); self; end
    def union(other); other; end
    def subtract(other); self; end
    def contain?(other); nil; end
    def inside?(other); nil; end
    def region_adjacent?(other)
      case other
      when SemiInterval
        raise ImpossibleComparison, "#{self}.region_adjacent?(#{other}) failed"
      when SemiIntervalSet
        raise UnsupportedType
      end
    end
    def from_left?(other); nil; end
    def from_right?(other); nil; end
    def intersect?(other); nil; end
    def ==(other); other.empty?; end
    def <=>(other); self == other ? 0 : nil; end
    def to_s; "[empty)"; end
    def covering_interval; self; end
    def complement; SemiInterval.new(-Float::INFINITY, Float::INFINITY); end
    def include_position?(pos); false; end
  end
end
