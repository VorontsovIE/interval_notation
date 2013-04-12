$:.unshift File.dirname(File.expand_path(__FILE__))
require 'region'
require 'bioinform/support/same_by'


# RegionList is immutable structure
#
# It maintains list of non-intersecting regions on the same strand of the same chromosome
# List is sorted according to strand direction, duplicates of regions removed.
# If any intersecting regions (except duplicates) or regions on different chromosomes/strands are found, then construction of list fails
#
# Empty RegionLists have no information about chromosome/strand even when created as intersection of non-intersecting regions on some strand

class RegionList
  attr_reader :list_of_regions

  # list_1 = RegionList.new( Region.new_by_annotation('chr1:10..15,+'), Region.new_by_annotation('chr1:21..42,+'), Region.new_by_annotation('chr1:30..31,+') )
  # list_2 = RegionList.new( Region.new_by_annotation('chr1:110..115,+'), Region.new_by_annotation('chr1:121..142,+') )
  # list_3 = RegionList.new( list_1, list_2 )
  def initialize(*list_of_regions)
    @list_of_regions = []
    list_of_regions.each do |region|
      case region
      when Region
        @list_of_regions << region
      when RegionList
        @list_of_regions.concat(region.list_of_regions)
      end
    end

    raise 'RegionList must contain regions on the same strand and chromosome'  unless @list_of_regions.same_by?(&:chromosome) && @list_of_regions.same_by?(&:strand)

    @list_of_regions = @list_of_regions.uniq.sort
  end

  def empty?
    list_of_regions.empty?
  end

  def chromosome
    empty? ? nil : list_of_regions.first.chromosome
  end
  def strand
    empty? ? nil : list_of_regions.first.strand
  end

  def to_s
    regions = list_of_regions.map{|region| "#{region.pos_start}..#{region.pos_end}"}.join(';')
    list_of_regions.empty? ? '' : "#{chromosome},#{strand}:<#{regions}>"
  end

  def ==(other)
    list_of_regions == other.list_of_regions
  end

  def eql?(other_region_list)
    self == other_region_list
  end

  def hash
    to_s.hash
  end

  def intersection(other_region)
    intersected_regions = list_of_regions.map{|region| region.intersect?(other_region) ? region.intersection(other_region) : nil }.compact
    RegionList.new(*intersected_regions)
  end
end