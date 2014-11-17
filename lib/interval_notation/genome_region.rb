# GenomeRegion is immutable structure. It's composed of interval / set of intervals, chromosome and strand
# It can be constructed using chromosome, strand and either pos_start,pos_end pair or interval/interval set
# All intervals in genome region should be on the same strand

require_relative 'interval_algebra'
include IntervalAlgebra

module GenomeRegionOperations
  def intersection(other)
    case other
    when GenomeRegion, GenomeRegionList
      raise ImpossibleComparison, 'Different strands or chromosomes'  unless same_strand?(other)
      GenomeRegion.new(chromosome, strand, region.intersection(other.region))
    else
      compatible_l, compatible_r = other.coerce(self)
      raise ImpossibleComparison, 'Different strands or chromosomes'  unless compatible_l.same_strand?(compatible_r)
      GenomeRegion.new(chromosome, strand, compatible_l.region.intersection(compatible_r.region))
    end
  end
  def union(other)
    case other
    when GenomeRegion, GenomeRegionList
      raise ImpossibleComparison, 'Different strands or chromosomes'  unless same_strand?(other)
      GenomeRegion.new(chromosome, strand, region.union(other.region))
    else
      compatible_l, compatible_r = other.coerce(self)
      raise ImpossibleComparison, 'Different strands or chromosomes'  unless compatible_l.same_strand?(compatible_r)
      GenomeRegion.new(chromosome, strand, compatible_l.region.union(compatible_r.region))
    end
  end
  def subtract(other)
    case other
    when GenomeRegion, GenomeRegionList
      raise ImpossibleComparison, 'Different strands or chromosomes'  unless same_strand?(other)
      GenomeRegion.new(chromosome, strand, region.subtract(other.region))
    else
      compatible_l, compatible_r = other.coerce(self)
      raise ImpossibleComparison, 'Different strands or chromosomes'  unless compatible_l.same_strand?(compatible_r)
      GenomeRegion.new(chromosome, strand, compatible_l.region.subtract(compatible_r.region))
    end
  end
  def complement
    GenomeRegion.new(chromosome, strand, region.complement)
  end
  def |(other); union(other); end
  def &(other); intersection(other); end
  def -(other); subtract(other); end
  def ~; complement; end
  def covering_region; GenomeRegion.new(chromosome, strand, region.covering_interval); end
end

module UpDownStream
  def most_upstream_region
    plus_strand? ? GenomeRegion.new(chromosome, strand, list_of_regions.first) : GenomeRegion.new(chromosome, strand, list_of_regions.last)
  end
  def most_downstream_region
    plus_strand? ? GenomeRegion.new(chromosome, strand, list_of_regions.last) : GenomeRegion.new(chromosome, strand, list_of_regions.first)
  end
  def most_upstream_pos
    most_upstream_region.pos_upstream
  end
  def most_downstream_pos
    most_downstream_region.pos_downstream
  end
  def leftmost_position
    region.leftmost_position
  end
  def rightmost_position
    region.rightmost_position
  end

  def upstream(len)
    if plus_strand?
      GenomeRegion.new(chromosome, strand, SemiInterval.new(leftmost_position - len, leftmost_position))
    else
      GenomeRegion.new(chromosome, strand, SemiInterval.new(rightmost_position, rightmost_position + len))
    end
  end
  def downstream(len)
    if plus_strand?
      GenomeRegion.new(chromosome, strand, SemiInterval.new(rightmost_position, rightmost_position + len))
    else
      GenomeRegion.new(chromosome, strand, SemiInterval.new(leftmost_position - len, leftmost_position))
    end
  end

  def with_upstream(len)
    self | upstream(len)
  end
  def with_downstream(len)
    self | downstream(len)
  end
end

module RegionConditionals
  def empty?
    region.empty?
  end
  def same_strand?(other)
    chromosome == other.chromosome && strand == other.strand
  end
  def intersect?(other)
    case other
    when GenomeRegion, GenomeRegionList
      #raise ImpossibleComparison, 'Different strands or chromosomes'  unless same_strand?(other)
      return false  unless same_strand?(other)
      region.intersect?(other.region)
    else
      compatible_l, compatible_r = other.coerce(self)
      compatible_l.intersect?(compatible_r)
    end
  end
  def contain?(other)
    case other
    when GenomeRegion, GenomeRegionList
      #raise ImpossibleComparison, 'Different strands or chromosomes'  unless same_strand?(other)
      return false  unless same_strand?(other)
      region.contain?(other.region)
    else
      compatible_l, compatible_r = other.coerce(self)
      compatible_l.contain?(compatible_r)
    end
  end
  def include_position?(pos)
    region.include_position?(pos)
  end
  #private :same_strand?
  def contigious?; region.contigious?; end
end

class GenomeRegion
  attr_reader :region, :chromosome, :strand, :pos_start, :pos_end

  def self.new_by_annotation(name)
    chromosome, name = name.split(':')
    name, strand = name.split(',')
    pos_start, pos_end = name.split(/\.\.|-/).map(&:to_i) # chr1:23..44,+  or  chr1:23-44,+
    self.new(chromosome, strand, SemiInterval.new(pos_start, pos_end))
  end

  def self.new_by_bed_line(line)
    chromosome, pos_start, pos_end, _name, _score, strand = line.chomp.split("\t")
    pos_start = pos_start.to_i
    pos_end = pos_end.to_i
    GenomeRegion.new(chromosome, strand, SemiInterval.new(pos_start, pos_end))
  end

  def initialize(chromosome, strand, region)
    @chromosome, @strand, @region = chromosome.to_sym, strand.to_sym, region
    raise ArgumentError  unless [:+, :-].include?(@strand)
  end

  def pos_start
    region.pos_start
  end
  def pos_end
    region.pos_end
  end
  def pos_upstream
    plus_strand? ? pos_start : pos_end
  end
  def pos_downstream
    plus_strand? ? pos_end : pos_start
  end
  def self.new(chromosome, strand, *region_data)
    case region_data.size
    when 1
      region = region_data.first
    when 2
      pos_start, pos_end = *region_data
      region = SemiInterval.new(pos_start, pos_end)
    else
      raise ArgumentError, 'Too many arguments. Region can be either (Empty)SemiInterval/SemiIntervalSet or pos_start, pos_end pair'
    end
    region = region & SemiInterval.new(0, Float::INFINITY)

    case region
    when SemiInterval
      super(chromosome, strand, region)
    when SemiIntervalSet
      GenomeRegionList.new(chromosome, strand, region)
    else
      raise UnsupportedType
    end
  end
  def to_s
    "#{chromosome}:#{region.pos_start}..#{region.pos_end},#{strand}"
  end
  def annotation; to_s; end
  def inspect; to_s; end

  def ==(other)
    same_strand?(other) && region == other.region
  end
  def eql?(other)
    self == other
  end
  def hash
    [chromosome, strand, region].hash
  end

  def plus_strand?
    strand == :+
  end
  def minus_strand?
    strand == :-
  end


  include GenomeRegionOperations
  include RegionConditionals
  include UpDownStream

  def length
    region.length
  end

  def <=>(other)
    return nil  unless same_strand?(other)
    return nil  unless region_comparison = (region <=> other.region)
    plus_strand? ? region_comparison : -region_comparison
  end
  include Comparable

  def splice(associated_data, region_list)
    raise 'list of regions for splicing should be on the same strand as source region' unless same_strand?(region_list)
    spliced_data = []
    local_pos = 0
    region.to_range.each do |pos|
      spliced_data << associated_data[local_pos]  if region_list.include_position?(pos)
      local_pos += 1
    end
    plus_strand? ? spliced_data : spliced_data.reverse
  end

  # genome_dir is a folder with files of different chromosomes
  # here we don't take strand into account
  def load_sequence(genome_dir)
    if self.empty?
      return ""
    end    
    @sequence_on_positive_strand ||= begin
      filename = File.join(genome_dir, "#{chromosome}.plain")
      File.open(filename) do |f|
        f.seek(region.pos_start)
        f.read(region.length)
      end
    end
  end

  # returns array of cages (not reversed on '-' strand)
  def load_cages(all_cages)
    if self.empty?
      return [] 
    end
    #caching here is a bad strategy because different tissues have different all_cages and yields different results
    #@cages ||= begin
      strand_of_cages = all_cages[strand][chromosome] || {}
      cages = Array.new(length)
      local_pos = 0
      region.to_range.each do |pos|
        cages[local_pos] = strand_of_cages.fetch(pos, 0)
        local_pos +=1
      end
      cages
    #end
  end

  def list_of_regions
    region.interval_list#.map{|interval| GenomeRegion.new(chromosome, strand, interval)}
  end

  # Danger method being combined with Enumerable!
  # Due to Eumerable #include? works not as expected
  # You can mix situation [region_1].inject(&:union) => region_1  and  region_1.inject => SemiInterval (region_1.region)
  def each(&block)
    if block_given?
      list_of_regions.each do |region|
        block.call(region)
      end
    else
      list_of_regions.enum_for(:each)
    end
  end
  def each_region(&block)
    if block_given?
      list_of_regions.each do |interval|
        block.call GenomeRegion.new(chromosome, strand, interval)
      end
    else
      self.enum_for(:each_region)
    end
  end
  include Enumerable
end

class GenomeRegionList
  attr_reader :region, :chromosome, :strand
  def initialize(chromosome, strand, region)
    @chromosome, @strand, @region = chromosome.to_sym, strand.to_sym, region
    raise ArgumentError  unless [:+, :-].include?(@strand)
  end
  def self.new(chromosome, strand, region)
    region = region & SemiInterval.new(0, Float::INFINITY)
    case region
    when SemiInterval
      GenomeRegion.new(chromosome, strand, region)
    when SemiIntervalSet
      super
    else
      raise UnsupportedType
    end
  end
  def to_s
    #"#{chromosome},#{strand}:#{region}"
    map{|interval| "#{chromosome}:#{interval.pos_start}..#{interval.pos_end},#{strand}"}.join(';')
  end
  def annotation; to_s; end
  def inspect; to_s; end

  def ==(other)
    same_strand?(other) && region == other.region
  end
  def eql?(other)
    self == other
  end
  def hash
    [chromosome, strand, region].hash
  end

  def plus_strand?
    strand == :+
  end
  def minus_strand?
    strand == :-
  end

  include GenomeRegionOperations
  include RegionConditionals

  include UpDownStream

  def list_of_regions
    region.interval_list#.map{|interval| GenomeRegion.new(chromosome, strand, interval)}
  end
  def each(&block)
    if block_given?
      list_of_regions.each do |region|
        block.call(region)
      end
    else
      list_of_regions.enum_for(:each)
    end
  end
  def each_region(&block)
    if block_given?
      list_of_regions.each do |interval|
        block.call GenomeRegion.new(chromosome, strand, interval)
      end
    else
      self.enum_for(:each_region)
    end
  end
  include Enumerable
end
