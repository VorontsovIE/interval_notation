# time ruby extract_5utr_and_cages.rb ~/iogen/cages/mm9/Mouse%20Embryonic%20fibroblasts%2c%20donor1.CNhs12130.11712-123C2.mm9.ctss.bed ~/iogen/cages/mm9/peaks_Mouse%20Embryonic%20fibroblasts%2c%20donor1.CNhs12130.11712-123C2.mm9.ctss.txt ~/programming/iogen/cage_analysis/source_data_mm9/mm_transcript_exons.txt 1000 ~/iogen/genome/mm9/ ~/programming/iogen/cage_analysis/source_data_mm9/mtor_regulated_transcripts_mm.txt > result_mm9/utrs.txt 2> result_mm9/log.txt


require 'logger'
require 'set'
require_relative 'lib/gene_data_loader'
require_relative 'lib/splicing'


# cages_file = 'source_data_2/embryonic%20kidney%20cell%20line%3a%20HEK293%2fSLAM%20untreated.CNhs11046.10450-106F9.hg19.ctss.bed'
# peaks_for_tissue_file = 'source_data_2/peaks_for_embryonic%20kidney%20cell%20line%3a%20HEK293%2fSLAM%20untreated.txt'
# transcript_infos_file = 'source_data/ensembl_transcripts.txt'
# region_length = 0
# genome_folder = 'source_data/genome/hg19'
# transcript_ids_filename = '/home/ilya/iogen/BioSchool-summer2014/mTOR_mat/from_sofia/mTOR_mat/mtor_regulated_transcripts_mm.txt'

raise 'Specify <cages (.bed)> <peaks> <transcripts exon markup> <region expand length> <genome (folder)> [transcript id-s (ensemble)]'  unless ARGV.size >= 5


gene_names_by_refseq = File.readlines('/home/ilya/iogen/BioSchool-summer2014/mTOR_mat/from_sofia/mTOR_mat/mouse_mTOR_targets.csv').map{|l| refseq, gene_symbol = l.chomp.split("\t").first(2); [refseq, gene_symbol] }.to_h
refseq_by_ensmust = File.readlines('/home/ilya/iogen/BioSchool-summer2014/mTOR_mat/from_sofia/mTOR_mat/refseq_MGI.txt').map{|l| refseq, ensmust, mgi = l.chomp.split("\t").first(3); [ensmust, refseq] }.to_h


cages_file, peaks_for_tissue_file, transcript_infos_file, region_length, genome_folder = ARGV.first(5)
transcript_ids_filename = ARGV[5]  if ARGV.size >= 6

region_length = region_length.to_i

framework = GeneDataLoader.new(cages_file,
                              peaks_for_tissue_file,
                              transcript_infos_file,
                              region_length,
                              genome_folder)

if transcript_ids_filename
  transcripts = File.readlines(transcript_ids_filename).map(&:strip)
  framework.transcript_ensts_to_load = Set.new( transcripts )
end

logger = Logger.new($stderr)
logger.formatter = ->(severity, datetime, progname, msg) { "#{severity}: #{msg}\n" }
framework.logger = logger
Gene.logger = logger

framework.setup!

File.open('transcripts_expression_mouse.txt', 'w') do |fw|
  # framework.output_all_5utr($stdout) #(fw)
  # framework.output_all_5utr($stdout) do |output_stream, enst, transcript_group, peaks_info, summary_expression, spliced_sequence, spliced_cages, utr, exons_on_utr|
  #   output_stream.puts "#{enst}\t#{summary_expression}\ttranscript_group: #{transcript_group}\tutr:#{utr}\texons_on_utr:#{exons_on_utr}\tseq_length:#{spliced_sequence.length}"
  # end
  framework.output_all_5utr($stdout) do |output_stream, enst, transcript_group, peaks_info, summary_expression, spliced_sequence, spliced_cages, utr, exons_on_utr|
    output_stream.puts ">#{enst}\t#{gene_names_by_refseq[refseq_by_ensmust[enst]]}\tSummary expression: #{summary_expression}\tTranscript: #{transcript_group}\tPeaks: #{peaks_info}"
    output_stream.puts spliced_sequence
    output_stream.puts spliced_sequence.each_char.to_a.join("\t")
    output_stream.puts spliced_cages.join("\t")
  end
end
