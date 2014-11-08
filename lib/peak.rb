require_relative 'intervals/genome_region'
require_relative 'transcript'
require_relative 'identificator_mapping'

class Peak
  attr_reader :annotation, :short_description, :description, :association_with_transcript,
              :entrezgene_id, :hgnc_ids, :uniprot_id, :tpm, :tpms
  def initialize(annotation, short_description, description, association_with_transcript, entrezgene_ids, hgnc_ids, uniprot_id, tpm)
    @annotation, @short_description, @description, @association_with_transcript, @entrezgene_ids, @hgnc_ids, @uniprot_id, @tpm = annotation, short_description, description, association_with_transcript, entrezgene_ids, hgnc_ids, uniprot_id, tpm
    @tpms = {}
  end

  def region
    @region ||= GenomeRegion.new_by_annotation(annotation)
  end

  # ENST transcript associations
  def enst_ids
    @enst_ids ||= begin
      if association_with_transcript == 'NA'
        []  
      else
        association_with_transcript.gsub(/_5end$/,'').gsub(/-?\d+bp_to_(,-?\d+bp_to_)?/,'').split(',').select{|identifier| identifier.start_with?('ENST') || identifier.start_with?('ENSMUST')}
      end
    end
  end

# # (!) human FANTOM
#   def self.new_by_infos(infos)
#     annotation, short_description, description, association_with_transcript, entrezgene, hgnc, uniprot_id, tpm = infos.chomp.split("\t")
#     tpm = tpm.to_f
#     hgnc_ids = hgnc.split(',').map{|hgnc_id| hgnc_from_string(hgnc_id)}
#     entrezgene_ids = entrezgene.split(',').map{|entrezgene_id| entrezgene_from_string(entrezgene_id)}
#     Peak.new(annotation, short_description, description, association_with_transcript, entrezgene_ids, hgnc_ids, uniprot_id, tpm)
#   end

# (!) mouse FANTOM
  def self.new_by_infos(infos)
    annotation, short_description, description, association_with_transcript, entrezgene, uniprot_id, tpm = infos.chomp.split("\t")
    tpm = tpm.to_f
    # hgnc_ids = hgnc.split(',').map{|hgnc_id| hgnc_from_string(hgnc_id)}
    entrezgene_ids = entrezgene.split(',').map{|entrezgene_id| entrezgene_from_string(entrezgene_id)}
    Peak.new(annotation, short_description, description, association_with_transcript, entrezgene_ids, [], uniprot_id, tpm)
  end

  def to_s
    "Peak<#{annotation}>"
  end

  def chromosome; region.chromosome; end
  def strand; region.strand; end
  def pos_start; region.pos_start; end
  def pos_end; region.pos_end; end

  def self.peaks_from_file(input_file)
    File.open(input_file) do |fp|
      fp.each_line.each_with_object([]) do |line, peaks|
        next unless line.start_with?('chr')  # this criteium can become insufficient when applied to Drosophila (it has differently named chromosomes)
        peaks << Peak.new_by_infos(line)
      end
    end
  end

  def ==(other)
    annotation == other.annotation
  end
  alias_method :eql? , :==
  def hash
    annotation.hash
  end

  def coerce(other)
    case other
    when GenomeRegion, GenomeRegionList
      [other, self.region]
    else
      raise "Can't coerce Peak to #{other.class}"
    end
  end

  # returns just regions not peaks
  def intersection(other)
    region.intersection(other)
  end
  def union(other)
    region.union(other)
  end
  def subtract(other)
    region.subtract(other)
  end
  def complement
    region.complement
  end
  def |(other); region.union(other); end
  def &(other); region.intersection(other); end
  def -(other); region.subtract(other); end
  def ~; region.complement; end
  def intersect?(other)
    ! intersection(other).empty?
  end
end
