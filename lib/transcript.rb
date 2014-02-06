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
    name, chromosome, strand, _tx_start, _tx_end, cds_start, cds_end, exon_count, exon_starts, exon_ends, protein_id, _align_id = info.split("\t")
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

  # return contigious untranslated 5'-region, including introns
  def utr_5
    raise "5'-UTR of non-coding gene is undefined"  unless coding?
    full_gene_region - coding_region.with_downstream(Float::INFINITY)
  end

  def expanded_upstream(region_length)
    Transcript.new(name, chromosome, strand, coding_region, exons.with_upstream(region_length), protein_id)
  end
  private :expanded_upstream

  def utr_5_with_upstream(region_length)
    # we should first expand, then take utr because some transcripts in UCSC don't have utr, their start marked at the same place, their coding region starts
    expanded_upstream(region_length).utr_5
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
      expanded_transcript = expanded_upstream(region_length).expand_and_trim_with_peaks(peaks)
      expanded_transcript.exons & expanded_transcript.utr_5
    end
  end
  private :calculate_exons_on_utr

  # utr_region is defined by leftmost peak intersecting region [txStart-region_length; coding_region_start) and by start of coding region
  def utr_region
    expanded_upstream(region_length).expand_and_trim_with_peaks(peaks_associated).utr_5
  end

  #
  # Elongate region to the most upstream peak which intersects transcript and trims at this point start
  # It gives us transcript lasting upstream to the last point with reasonable expression (i.e. to a peak)
  # Usually this procedure is applied after transcript was elongated 100-1000 bp from annotated txStart
  # so +#expand_and_trim_with_peaks+ usually trims over-expanded transcript to its real start
  # But if transcript intersects peak in its(peak) middle, we elongate transcript to take whole the peak
  #
  # Note that first-stage elongation should be done explicit with +#expanded_upstream+!
  #
  #
  # First case - trimming when all peaks intersecting with transcript are downstream to transcript start:
  # transcript                                 (_____)^^^^(___)^(_______)
  # peaks                                         (.)  (..)
  # most_upstream_peak                            (.)
  # peak_with_downstream                          (............................
  # upstream of transcript  ...................)
  # region expansion                          Empty
  # exons_expanded (result)                       (__)^^^^(___)^(_______)
  #
  #
  # Second case - intersecting peak expands transcript region when it intersects with transcript but lies upstream to its start:
  # transcript                                 (_____)^^^^(___)^(_______)
  # peaks                             (..) (.....) (.)
  # most_upstream_peak                     (.....)
  # peak_with_downstream                   (.................................
  # upstream of transcript  ...................)
  # region expansion                       (...)
  # exons_expanded (result)                (_________)^^^^(___)^(_______)
  #
  def expand_and_trim_with_peaks(peaks)
    transcript_region = full_gene_region
    peaks_intersecting_region = peaks.select{|peak| peak.intersect?(transcript_region) }
    if peaks_intersecting_region.empty?
      self
    else
      most_upstream_peak = peaks_intersecting_region.map(&:region).min
      peak_with_downstream = most_upstream_peak.with_downstream(Float::INFINITY)
      region_expansion = exons.upstream(Float::INFINITY) & peak_with_downstream
      exons_expanded = (exons | region_expansion) & peak_with_downstream
      Transcript.new(name, chromosome, strand, coding_region, exons_expanded, protein_id)
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
