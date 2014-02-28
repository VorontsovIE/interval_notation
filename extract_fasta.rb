require 'logger'
require 'set'
require_relative 'lib/gene_data_loader'
require_relative 'lib/splicing'

def load_transcripts_fold_change(input_file)
  mtor_lines = File.readlines(input_file)
  column_indices = column_indices(mtor_lines[0], {enst: 'txids', fold_change: 'pp242.TE FOLD_CHANGE'})
  mtor_lines.drop(1).each_with_object(Hash.new) do |line, transcripts_fold_change|
    enst, fold_change = *extract_columns(line, [:enst, :fold_change], column_indices)
    transcripts_fold_change[enst] = fold_change
  end
end

min_expression = -Float::INFINITY
cages_file = 'source_data_2/embryonic%20kidney%20cell%20line%3a%20HEK293%2fSLAM%20untreated.CNhs11046.10450-106F9.hg19.ctss.bed'
peaks_for_tissue_file = 'source_data_2/peaks_for_embryonic%20kidney%20cell%20line%3a%20HEK293%2fSLAM%20untreated.txt'
transcript_infos_file = 'source_data/ensembl_transcripts.txt'
region_length = 0
genome_folder = 'source_data/genome/hg19'

framework = GeneDataLoader.new(cages_file,
                              peaks_for_tissue_file,
                              transcript_infos_file,
                              region_length,
                              genome_folder)

transcripts = File.readlines('source_data_2/reads_vs_hg19_gencodeComprehensive.stats').select{|l| l.strip.split.first.match(/ENST\d+/) }

framework.transcript_ensts_to_load = Set.new( transcripts.map{|line| line.split.first.match(/ENST\d+/)[0] } )

logger = Logger.new($stderr)
logger.formatter = ->(severity, datetime, progname, msg) { "#{severity}: #{msg}\n" }
framework.logger = logger
Gene.logger = logger

framework.setup!

File.open('transcripts_expression_3.txt', 'w') do |fw|
  framework.output_all_5utr(fw) do |output_stream, enst, transcript_group, peaks_info, summary_expression, spliced_sequence, spliced_cages, utr, exons_on_utr|
    output_stream.puts "#{enst}\t#{summary_expression}"
  end
end

# File.open('weighted_5-utr-polyN-masked_1.txt', 'w') do |fw|
#   framework.output_all_5utr(genes_to_extract, fw) do |output_stream, gene_info, transcript_group, peaks_info, expression, spliced_sequence, spliced_cages|
#     next  unless expression >= min_expression
#     output_stream.puts ">#{gene_info}\t#{transcript_group}\t#{expression}"
#     output_stream.puts mark_best_starts_as_poly_n(spliced_sequence, spliced_cages, 0.7, 0)
#   end
# end

# File.open('weighted_5-utr-polyN-masked_5.txt', 'w') do |fw|
#   framework.output_all_5utr(genes_to_extract, fw) do |output_stream, gene_info, transcript_group, peaks_info, expression, spliced_sequence, spliced_cages|
#     next  unless expression >= min_expression
#     output_stream.puts ">#{gene_info}\t#{transcript_group}\t#{expression}"
#     output_stream.puts mark_best_starts_as_poly_n(spliced_sequence, spliced_cages, 0.7, 2)
#   end
# end

# File.open('weighted_5-utr-polyN-masked_good.txt', 'w') do |fw|
  # framework.output_all_5utr(genes_to_extract, fw) do |output_stream, gene_info, transcript_group, peaks_info, expression, spliced_sequence, spliced_cages|
    # next  unless expression >= min_expression
    # output_stream.puts ">#{gene_info}\t#{transcript_group}\t#{expression}"
    # output_stream.puts mark_single_best_start_as_poly_n(spliced_sequence, spliced_cages, 5)
  # end
# end
