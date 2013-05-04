$:.unshift File.dirname(File.expand_path(__FILE__))
require 'genome_region'
require 'transcript'

class Peak
  attr_reader :annotation, :short_description, :description, :association_with_transcript,
              :entrezgene_id, :hgnc_id, :uniprot_id, :tpm, :tpms
  def initialize(annotation, short_description, description, association_with_transcript, entrezgene_id, hgnc_id, uniprot_id, tpm)
    @annotation, @short_description, @description, @association_with_transcript, @entrezgene_id, @hgnc_id, @uniprot_id, @tpm = annotation, short_description, description, association_with_transcript, entrezgene_id, hgnc_id, uniprot_id, tpm
    @tpms = {}
  end

  def region
    @region ||= GenomeRegion.new_by_annotation(annotation)
  end

  # Returns an array of peaks (for each hgnc and entrezgene sticking hgnc and entrezgene together accordantly) basically the same but linked to different genes
  ### (line with infos shortened for brevity)
  ### Peak.new_peaks_by_infos('chr10:102289611..102289643,- p1@NDUFB8,p1@SEC31B CAGE_peak_1_at_NDUFB8_5end,CAGE_peak_1_at_SEC31B_5end 0bp_to_AF044958,AF077028,AF115968,NM_005004,uc010qpq.1,uc010qpr.1_5end  entrezgene:4714,entrezgene:25956  HGNC:7703,HGNC:23197  uniprot:O95169,uniprot:A8KAL6 62.734510667127')
  def self.new_peaks_by_infos(infos, hgnc_to_entrezgene, entrezgene_to_hgnc)
    annotation, short_description, description, association_with_transcript, entrezgene, hgnc, uniprot_id, tpm = infos.strip.split("\t")
    tpm = tpm.to_f
    hgnc_ids = hgnc.split(',').map{|hgnc_id| hgnc_id.split(':').last.to_i}
    entrezgene_ids = entrezgene.split(',').map{|entrezgene_id| entrezgene_id.split(':').last.to_i}
    hgnc_entrezgene_combine(hgnc_to_entrezgene, entrezgene_to_hgnc, hgnc_ids, entrezgene_ids).map{|hgnc_id, entrezgene_id|
      self.new(annotation, short_description, description, association_with_transcript, entrezgene_id, hgnc_id, uniprot_id, tpm)
    }
  end

  def to_s
    "Peak<#{annotation}; gene HGNC:#{hgnc_id}>"
  end

  def chromosome; region.chromosome; end
  def strand; region.strand; end
  def pos_start; region.pos_start; end
  def pos_end; region.pos_end; end

  # hgnc_id => [peaks]
  def self.peaks_from_file(input_file, hgnc_to_entrezgene, entrezgene_to_hgnc)
    peaks = {}
    File.open(input_file) do |fp|
      fp.each_line do |line|
        next unless line.start_with?('chr')  # this criteium can become insufficient when applied to Drosophila (it has differently named chromosomes)
        pack_of_peaks = Peak.new_peaks_by_infos(line, hgnc_to_entrezgene, entrezgene_to_hgnc)
        pack_of_peaks.each do |peak|
          next unless peak.hgnc_id
          peaks[peak.hgnc_id] ||= []
          peaks[peak.hgnc_id] << peak
        end
      end
    end
    peaks
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