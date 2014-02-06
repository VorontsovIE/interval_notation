require_relative 'intervals/genome_region'
require_relative 'peak'

class Transcript
  attr_reader :name, :chromosome, :strand, :coding_region, :exons, :protein_id
  attr_accessor :peaks_associated, :region_length
  attr_accessor :exons_on_utr

  def initialize(name, chromosome, strand, coding_region, exons, protein_id)
    @name, @chromosome, @strand, @coding_region, @exons, @protein_id  = name, chromosome, strand, coding_region, exons, protein_id
  end

  # Transcript.new_by_infos('uc001aaa.3 chr1  + 11873 14409 11873 11873 3 11873,12612,13220,  12227,12721,14409,    uc001aaa.3')
  # We don't remove version from name not to have a bug with  uc010nxr.1(chr1)  and  uc010nxr.2(chrY)
  # Be careful about real versions of transcripts, use synchronized databases
  def self.new_by_infos(info)
    name, chromosome, strand, tx_start, tx_end, cds_start, cds_end, exon_count, exon_starts, exon_ends, protein_id, _align_id = info.split("\t")
    exon_starts = exon_starts.split(',').map(&:strip).reject(&:empty?).map(&:to_i)
    exon_ends = exon_ends.split(',').map(&:strip).reject(&:empty?).map(&:to_i)
    coding_region = GenomeRegion.new(chromosome, strand, cds_start.to_i, cds_end.to_i)  ### rescue nil
    exon_regions = exon_count.to_i.times.map{|index| SemiInterval.new(exon_starts[index], exon_ends[index])} ##############
    exons = GenomeRegion.new(chromosome, strand, SemiIntervalSet.new(exon_regions))
    self.new(name, chromosome, strand, coding_region, exons, protein_id)
  end

  def coding?
    ! coding_region.empty?
  end
  def to_s
    protein_infos = protein_id ? "(#{protein_id})" : ""
    "Transcript<#{name}#{protein_infos}; #{full_gene_region}; coding_region #{coding_region}; exons #{exons}>"
  end
  alias_method :inspect, :to_s
  def full_gene_region
    exons.covering_region
  end

  def utr_5_with_upstream
    full_gene_region.with_upstream(region_length) - coding_region.with_downstream(Float::INFINITY)
  end
  private :utr_5_with_upstream

  # region_length is length of region before txStart(start of transcript) where we are looking for peaks
  def associate_peaks(peaks, region_length)
    @region_length = region_length
    @peaks_associated ||= begin
      region_of_interest = calculate_exons_on_utr(peaks)
      peaks.select{|peak| region_of_interest.intersect?(peak) }
    end
  end

  def calculate_exons_on_utr(peaks)
    @exons_on_utr = begin
      exons_on_utr_unexpanded = exons.with_upstream(region_length) & utr_5_with_upstream
      # expand ROI to include those peaks that intersect ROI
      region_expanded_upstream_with_peaks(exons_on_utr_unexpanded, peaks)
    end
  end
  private :calculate_exons_on_utr

  # utr_region is defined by leftmost peak intersecting region [txStart-region_length; coding_region_start) and by start of coding region
  def utr_region
    region_expanded_upstream_with_peaks(utr_5_with_upstream, peaks_associated)
  end

  # expand region to most upstream peaks and trim at that point (so result can be even shorter if peaks located downstream from start)
  def region_expanded_upstream_with_peaks(region, peaks)
    peaks_intersecting_region = peaks.select{|peak| region.intersect?(peak.region) }
    if peaks_intersecting_region.empty?
      region
    else
      most_upstream_peak = peaks_intersecting_region.map(&:region).min
      peak_with_downstream = most_upstream_peak.with_downstream(Float::INFINITY)
      region_expansion = region.most_upstream_region.upstream(Float::INFINITY).intersection(peak_with_downstream)
      region.union(region_expansion).intersection(peak_with_downstream)
    end
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
