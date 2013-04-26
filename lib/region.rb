$:.unshift File.dirname(File.expand_path(__FILE__))
require 'genome_region'
Region = GenomeRegion
=begin
# Region is immutable structure
#
# It contains semi-interval [pos_start; pos_end) on specified chromosome and strand('+'/'-')
# It's required that pos_start < pos_end.
# Regions can be ordered if they are on the same strand and don't intersect.
# Ordering depends on strand: plus-strand regions ordered as their coordinates, minus-strand regions ordered contrary-wise

class Region
  attr_reader :chromosome, :strand, :pos_start, :pos_end

  def ==(other_region)
    chromosome == other_region.chromosome && strand == other_region.strand && pos_start == other_region.pos_start && pos_end == other_region.pos_end
  end
  def eql?(other_region)
    self == other_region
  end

  def hash
    annotation.hash
  end

  # region represented a semi-interval: [pos_start; pos_end) Positions are 0-based
  def initialize(chromosome, strand, pos_start, pos_end)
    @chromosome, @strand, @pos_start, @pos_end = chromosome, strand, pos_start, pos_end
    pos_start = 0  if @pos_start < 0
    raise "Strand can be only + or - but was #{strand.inspect}"  unless ["+", "-"].include?(strand)
    raise "Negative length for region #{annotation}"  if length <= 0
  end

  # Region.new_by_annotation('chr1:564462..564463,+')
  def self.new_by_annotation(name)
    chromosome, name = name.split(':')
    name, strand = name.split(',')
    pos_start, pos_end = name.split('..').map(&:to_i)
    self.new(chromosome, strand, pos_start, pos_end)
  end
  def annotation
    "#{@chromosome}:#{@pos_start}..#{@pos_end},#{@strand}"
  end

  alias_method :to_s, :annotation
  alias_method :inspect, :annotation

  def intersect?(other_region)
    #same_strand?(other_region) && (include?(other_region) || other_region.include?(self) || include_position?(other_region.pos_start) || (include_position?(other_region.pos_end) && other_region.pos_end != pos_start))
    same_strand?(other_region) && !(pos_start >= other_region.pos_end || other_region.pos_start >= pos_end)
  end

  def intersection(other_region)
    return nil unless same_strand?(other_region)
    return nil unless intersect?(other_region)
    # self is [], other_region is ()

    if pos_start < other_region.pos_start && other_region.include_position?(pos_end) && other_region.pos_start != pos_end
      # [ ( ] )
      Region.new(chromosome, strand, other_region.pos_start, pos_end)
    elsif pos_end > other_region.pos_end && other_region.include_position?(pos_start)
      # ( [ ) ]
      Region.new(chromosome, strand, pos_start, other_region.pos_end)
    elsif other_region.contain?(self)
      # ( [ ] )
      self
    elsif contain?(other_region)
      # [ ( ) ]
      other_region
    else
      raise 'Logic error! Intersection undefined'
    end
  end

  def length
    pos_end - pos_start
  end

  # genome_dir is a folder with files of different chromosomes
  # here we don't take strand into account
  def load_sequence(genome_dir)
    @sequence_on_positive_strand ||= begin
      filename = File.join(genome_dir, "#{chromosome}.plain")
      File.open(filename) do |f|
        f.seek(pos_start)
        f.read(length)
      end
    end
  end

  # returns array of cages (not reversed on '-' strand)
  def load_cages(all_cages)
    #caching here is a bad strategy because different tissues have different all_cages and yields different results
    #@cages ||= begin
      strand_of_cages = all_cages[strand][chromosome]
      cages = Array.new(length)
      local_pos = 0
      region.each do |pos|
        cages[local_pos] = strand_of_cages.fetch(pos, 0)
        local_pos +=1
      end
      cages
    #end
  end

  # compare regions if they are comparable
  # regions are compared taking strand into account (on + strand A < B; on - strand B < A)
  # 0 1 2 ...
  # ------
  #  A  B
  # ------
  def <=>(other)
    return nil  unless same_strand?(other)
    if self == other
      0
    elsif pos_end <= other.pos_start
      strand == '+' ? -1 : +1
    elsif other.pos_end <= pos_start
      strand == '+' ? +1 : -1
    else
      nil
    end
  end
  include Comparable

  # whether other_region is inside of region
  def contain?(other_region)
    same_strand?(other_region) && include_position?(other_region.pos_start) && (include_position?(other_region.pos_end) || pos_end == other_region.pos_end)
  end

  def same_strand?(other_region)
    other_region.chromosome == chromosome && other_region.strand == strand
  end
  private :same_strand?

  # whether pos is inside of region provided that strand and chromosome are the same
  def include_position?(pos)
    region.include?(pos)
  end
  #private :include_position?


  # method to be removed
  def region
    @region ||= pos_start...pos_end
  end

  # external contact of regions
  def contact?(other_region)
    same_strand?(other_region) && (pos_start == other_region.pos_end || pos_end == other_region.pos_start)
  end

  # region of length `len` upstream from this region (jointed)
  def upstream(len)
    if strand == '+'
      Region.new(chromosome, strand, pos_start - len, pos_start)
    else
      Region.new(chromosome, strand, pos_end, pos_end + len)
    end
  end

  # region of length `len` downstream from this region (jointed)
  def downstream(len)
    if strand == '+'
      Region.new(chromosome, strand, pos_end, pos_end + len)
    else
      Region.new(chromosome, strand, pos_start - len, pos_start)
    end
  end

  def with_upstream(len)
    self.union(self.upstream(len))
  end
  def with_downstream(len)
    self.union(self.downstream(len))
  end

  # is pos upstream/downstream of region
  def position_upstream?(pos)
    (strand == '+') ? pos < pos_start : pos >= pos_end
  end
  def position_downstream?(pos)
    (strand == '+') ? pos >= pos_end : pos < pos_start
  end

  def splice(associated_data, region_list)
    raise 'list of regions for splicing should be on the same strand as source region' unless same_strand?(region_list)
    spliced_data = []
    local_pos = 0
    region.each do |pos|
      spliced_data << associated_data[local_pos]  if region_list.include_position?(pos)
      local_pos += 1
    end
    strand == '+' ? spliced_data : spliced_data.reverse
  end

  def union(other_region)
    RegionList.new(self).union(other_region)
  end
  alias_method :+, :union

  def subtract(other_region)
    case other_region
    when NilClass
      self
    when Region
      return self  unless intersect?(other_region)
      return RegionList.new()  if other_region.contain?(self)
      if contain?(other_region) && pos_start != other_region.pos_start && pos_end != other_region.pos_end
        RegionList.new(Region.new(chromosome, strand, pos_start, other_region.pos_start), Region.new(chromosome, strand, other_region.pos_end, pos_end) )
      elsif include_position?(other_region.pos_end)
        RegionList.new( Region.new(chromosome, strand, other_region.pos_end, pos_end) )
      elsif include_position?(other_region.pos_start)
        RegionList.new( Region.new(chromosome, strand, pos_start, other_region.pos_start) )
      else
        raise 'My algorithm failed being crushed by my stupidity'
      end
    when RegionList
      other_region.list_of_regions.inject(self){|result, region| result.subtract(region) }
    else
      raise 'unsupported object to subtract'
    end
  end
  alias_method :-, :subtract

  def list_of_regions
    [self]
  end
  def most_upstream_region
    self
  end

  def most_downstream_region
    self
  end

end
=end