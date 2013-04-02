$:.unshift File.dirname(File.expand_path(__FILE__))
require 'transcript'
require 'peak'

class TranscriptGroup
  attr_reader :utr, :exons_on_utr, :transcripts
  def initialize(utr, exons_on_utr, transcripts)
    @utr, @exons_on_utr, @transcripts = utr, exons_on_utr, transcripts
    raise 'TranscriptGroup can\'t be empty' if @transcripts.empty?
  end
  def peaks_associated(peaks, region_length)
    # each transcript in group has the same peaks associated so we take one of transcripts to obtain peaks
    transcripts.first.peaks_associated(peaks, region_length)
  end
  def to_s
    exon_infos = exons_on_utr.map(&:to_s).join(';')
    transcripts_infos = transcripts.map{|transcript| transcript.name }.join(';')
    "#{utr}\t#{exon_infos}\t#{transcripts_infos}"
  end
end