require_relative 'intervals/genome_region'
require_relative 'peak'

class Transcript
  attr_reader :name, :coding_region, :exons, :protein_id
  attr_accessor :peaks_associated

  def initialize(name, coding_region, exons, protein_id)
    raise "Coding region is outside of exons"  unless exons.covering_region.contain?(coding_region)
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
    exon_regions = exon_count.to_i.times.map{|index| IntervalAlgebra::SemiInterval.new(exon_starts[index], exon_ends[index])} ##############
    exons = GenomeRegion.new(chromosome, strand, IntervalAlgebra::SemiIntervalSet.new(exon_regions))
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
    @transcript_region ||= exons.covering_region
  end
  private :transcript_region

  # return contigious untranslated 5'-region, including introns
  def utr_5
    raise "5'-UTR of non-coding gene is undefined"  unless coding?
    @utr_5 ||= transcript_region - coding_region.with_downstream(Float::INFINITY)
  end

  def expanded_upstream(region_length)
    (region_length == 0) ? self : Transcript.new(name, coding_region, exons.with_upstream(region_length), protein_id)
  end

  def peaks_intersecting_transcript(peaks)
    peaks.select{|peak| transcript_region.intersect?(peak.region) }
  end

  def peaks_intersecting_exons_on_utr(peaks)
    peaks.select{|peak| exons_on_utr.intersect?(peak.region) }
  end

  def associate_peaks(peaks)
    @peaks_associated = peaks # peaks_intersecting_exons_on_utr(peaks)
  end

  def exons_on_utr
    @exons_on_utr ||= exons & utr_5
  end

  #
  # Elongate region to the most upstream peak and trims transcript's start at this point
  # It gives us transcript lasting upstream to the last point with reasonable expression (i.e. to a peak)
  # Usually this procedure is applied to peaks which intersect transcript being elongated upstream
  # by 100-1000 bp from annotated txStart. Also peaks annotated as related to a transcript can be used
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
  # In case there are no peaks, method returns nil
  #
  def expand_and_trim_with_peaks(peaks)
    if peaks.empty?
      nil
    else
      most_upstream_peak = peaks.map(&:region).min
      peak_with_downstream = most_upstream_peak.with_downstream(Float::INFINITY)
      region_expansion = exons.upstream(Float::INFINITY) & peak_with_downstream
      exons_expanded = (exons | region_expansion) & peak_with_downstream
      Transcript.new(name, coding_region, exons_expanded, protein_id)
    end
  end


  # ucsc_id => transcript
  def self.transcripts_from_file(input_file)
    File.open(input_file) do |fp|
      fp.each_line.map do |line|
        Transcript.new_by_infos(line)
      end
    end
  end
end
