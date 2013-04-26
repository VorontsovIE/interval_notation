$:.unshift File.dirname(File.expand_path(__FILE__))
require 'transcript'
require 'peak'


# Group transcripts for a gene so that several transcripts having the same
# exon-intron structure on UTR are taken altogether as a TranscriptGroup. Now
# we can treat transcript group, as a single transcript.
# This makes sense because we have no that much information about distinct
# transcripts to distinguish them when their structure on the region of interest
# is the same. So it's useful to just glue them up and treat as one transcript group

class TranscriptGroup
  attr_reader :utr, :exons_on_utr, :transcripts, :associated_peaks
  attr_accessor :summary_expression
  def initialize(utr, exons_on_utr, transcripts, associated_peaks)
    @utr, @exons_on_utr, @transcripts, @associated_peaks = utr, exons_on_utr, transcripts, associated_peaks
    raise 'TranscriptGroup can\'t be empty' if @transcripts.empty?
  end
  # def peaks_associated(peaks, region_length)
  #   # each transcript in group has the same peaks associated so we take one of transcripts to obtain peaks
  #   transcripts.first.peaks_associated(peaks, region_length)
  # end
  def to_s
    exon_infos = exons_on_utr.map{|interval| "#{interval.pos_start}..#{interval.pos_end}"}.join(';')
    transcripts_infos = transcripts.map{|transcript| transcript.name }.join(';')
    "#{utr}\t#{exon_infos}\t#{transcripts_infos}"
  end
end