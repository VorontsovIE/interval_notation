require 'logger'
require_relative 'lib/gene_data_loader'
require_relative 'lib/splicing'

min_expression = -1000.0

cages_file = 'prostate%20cancer%20cell%20line%253aPC-3.CNhs11243.10439-106E7.hg19.ctss.bed'
gene_by_hgnc_file            = 'HGNC_protein_coding_22032013_entrez.txt'
hgnc_entrezgene_mapping_file = 'HGNC_protein_coding_22032013_entrez.txt'
transcript_by_entrezgene_file = 'knownToLocusLink.txt'
peaks_for_tissue_file = 'robust_set.freeze1.reduced.pc-3'
transcript_infos_file = 'knownGene.txt'
region_length = 100
genome_folder = 'source_data/genome/hg19'

framework = GeneDataLoader.new(cages_file,
                              gene_by_hgnc_file,
                              hgnc_entrezgene_mapping_file,
                              transcript_by_entrezgene_file,
                              peaks_for_tissue_file,
                              transcript_infos_file,
                              region_length,
                              genome_folder)
logger = Logger.new($stderr)
logger.formatter = ->(severity, datetime, progname, msg) { "#{severity}: #{msg}\n" }
framework.logger = logger
Gene.logger = logger

framework.setup!




mtor_targets, translational_genes = read_mtor_mapping('mTOR_mapping.txt')
genes_to_extract = framework.genes_to_process.select{|hgnc_id, gene| mtor_targets.has_key?(hgnc_id)}

File.open('weighted_5-utr.txt', 'w') do |fw|
  framework.output_all_5utr(genes_to_extract, fw) do |output_stream, gene_info, transcript_group, peaks_info, expression, spliced_sequence, spliced_cages|
    next  unless expression >= min_expression
    output_stream.puts ">#{gene_info}\t#{transcript_group}\t#{expression}"
    output_stream.puts ">#{spliced_cages.join("\t")}"
    output_stream.puts spliced_sequence
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
