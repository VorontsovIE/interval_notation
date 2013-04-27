$:.unshift File.dirname(File.expand_path(__FILE__))
require 'genome_region'
require 'peak'

class Transcript
  attr_reader :name, :chromosome, :strand, :full_gene_region, :coding_region, :exons, :protein_id, :align_id

  def initialize(name, chromosome, strand, full_gene_region, coding_region, exons, protein_id, align_id)
    @name, @chromosome, @strand, @full_gene_region, @coding_region, @exons, @protein_id, @align_id  = name, chromosome, strand, full_gene_region, coding_region, exons, protein_id, align_id
  end

  # Transcript.new_by_infos('uc001aaa.3 chr1  + 11873 14409 11873 11873 3 11873,12612,13220,  12227,12721,14409,    uc001aaa.3')
  # We don't remove version from name not to have a bug with  uc010nxr.1(chr1)  and  uc010nxr.2(chrY)
  # Be careful about real versions of transcripts, use synchronized databases
  def self.new_by_infos(info)
    name, chromosome, strand, tx_start, tx_end, cds_start, cds_end, exon_count, exon_starts, exon_ends, protein_id, align_id = info.split("\t")
    exon_starts = exon_starts.split(',').map(&:strip).reject(&:empty?).map(&:to_i)
    exon_ends = exon_ends.split(',').map(&:strip).reject(&:empty?).map(&:to_i)
    full_gene_region = GenomeRegion.new(chromosome, strand, tx_start.to_i, tx_end.to_i)
    coding_region = GenomeRegion.new(chromosome, strand, cds_start.to_i, cds_end.to_i)  ### rescue nil
    exon_regions = exon_count.to_i.times.map{|index| SemiInterval.new(exon_starts[index], exon_ends[index])} ##############
    exons = GenomeRegion.new(chromosome, strand, SemiIntervalSet.new(exon_regions))
    self.new(name, chromosome, strand, full_gene_region, coding_region, exons, protein_id, align_id)
  end

  def coding?
    ! coding_region.empty?
  end
  def to_s
    protein_infos = protein_id ? "(#{protein_id})" : ""
    "Transcript<#{name}#{protein_infos}; #{full_gene_region}; coding_region #{coding_region}; exons #{exons}>"
  end
  alias_method :inspect, :to_s


  def utr_5_with_upstream(region_length)
    full_gene_region_w_upstream = full_gene_region.with_upstream(region_length)
    coding_region_w_downstream = coding_region.with_downstream(Float::INFINITY)
    full_gene_region_w_upstream.subtract(coding_region_w_downstream)
  end
  private :utr_5_with_upstream

  # region_length is length of region before txStart(start of transcript) where we are looking for peaks
  def peaks_associated(peaks, region_length)
    region_of_interest = exons_on_utr(peaks, region_length)
    peaks.select{|peak| region_of_interest.intersect?(peak) }
  end

  def exons_on_utr(peaks, region_length)
    utr = utr_5_with_upstream(region_length)

    exons_on_utr_unexpanded = exons.with_upstream(region_length).intersection(utr)
    # expand ROI to include those peaks that intersect ROI
    exons_on_utr_unexpanded.expand_upstream_with_peaks(peaks)
  end

  # utr_region is defined by leftmost peak intersecting region [txStart-region_length; coding_region_start) and by start of coding region
  def utr_region(peaks, region_length)
    utr_5_with_upstream(region_length).expand_upstream_with_peaks(peaks)
  end

  # ucsc_id => transcript
  def self.transcripts_from_file(input_file)
    transcripts = {}
    File.open(input_file) do |fp|
      fp.each_line do |line|
        transcript = Transcript.new_by_infos(line)
        transcripts[transcript.name] = transcript
      end
    end
    transcripts
  end
end