$:.unshift File.dirname(File.expand_path(__FILE__))
require 'region'
require 'bioinform/support/same_by'


# Maintain list of non-intersecting regions on the same strand of the same chromosome
# List is sorted according to strand direction, duplicates of regions removed.
# If any intersecting regions (except duplicates) or regions on different chromosomes/strands're found - construction of list fails
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
  
#  def intersection(region)
#    
#  end
end