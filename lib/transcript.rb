require_relative 'intervals/genome_region'
require_relative 'peak'

class Transcript
  attr_reader :name, :coding_region, :exons, :protein_id
  attr_accessor :peaks_associated

  def initialize(name, coding_region, exons, protein_id)
    @name, @coding_region, @exons, @protein_id  = name, coding_region, exons, protein_id
  end

  def chromosome
    @chromosome ||= exons.chromosome
  end

  def strand
    @strand ||= exons.strand
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
    Transcript.new(name, coding_region, exons, protein_id)
  end

  def coding?
    ! coding_region.empty?
  end

  def to_s
    protein_infos = protein_id ? "(#{protein_id})" : ""
    "Transcript<#{name}#{protein_infos}; #{transcript_region}; coding_region #{coding_region}; exons #{exons}>"
  end
  alias_method :inspect, :to_s

  # contigious region covering whole transcript
  def transcript_region
    exons.covering_region
  end
  private :transcript_region

  # return contigious untranslated 5'-region, including introns
  def utr_5
    raise "5'-UTR of non-coding gene is undefined"  unless coding?
    transcript_region - coding_region.with_downstream(Float::INFINITY)
  end

  def expanded_upstream(region_length)
    Transcript.new(name, coding_region, exons.with_upstream(region_length), protein_id)
  end
  private :expanded_upstream

  def peaks_intersecting_transcript(peaks)
    peaks.select{|peak| transcript_region.intersect?(peak) }
  end

  def associate_peaks(peaks)
    @peaks_associated ||= peaks_intersecting_transcript(peaks)
  end

  def exons_on_utr
    exons & utr_5
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
    peaks_intersecting_region = peaks_intersecting_transcript(peaks)
    if peaks_intersecting_region.empty?
      self
    else
      most_upstream_peak = peaks_intersecting_region.map(&:region).min
      peak_with_downstream = most_upstream_peak.with_downstream(Float::INFINITY)
      region_expansion = exons.upstream(Float::INFINITY) & peak_with_downstream
      exons_expanded = (exons | region_expansion) & peak_with_downstream
      Transcript.new(name, coding_region, exons_expanded, protein_id)
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
