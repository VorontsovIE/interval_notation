require 'logger'
$logger = Logger.new($stderr)
$logger.formatter = proc do |severity, datetime, progname, msg|
  "#{severity}: #{msg}\n"
end


$:.unshift File.join(File.dirname(File.expand_path(__FILE__)), 'lib')
require 'gene_data_loader'


# marks best start (top `rate` part of them) with poly-N so that motif finding ignore them
def mark_best_starts_as_poly_n(sequence, cages, rate)
  new_sequence = sequence.dup
  sum_cages = cages.inject(&:+)
  cages_taken = 0
  cages_sorted = cages.each_with_index.sort_by{|cage, index| cage}.reverse
  while cages_taken + cages_sorted.first.first <= sum_cages * 0.7
    cage, index = cages_sorted.shift
    cages_taken += cage
    new_sequence[index] = 'N'
  end
  new_sequence
end


cages_file = 'prostate%20cancer%20cell%20line%253aPC-3.CNhs11243.10439-106E7.hg19.ctss.bed'
framework = GeneDataLoader.new(cages_file, 'HGNC_protein_coding_22032013_entrez.txt', 'knownToLocusLink.txt', 'robust_set.freeze1.reduced.pc-3', 'knownGene.txt', 100)
mtor_targets, translational_genes = read_mtor_mapping('mTOR_mapping.txt')
genes_to_extract = framework.genes_to_process.select{|hgnc_id, gene| mtor_targets.has_key?(hgnc_id)}

File.open('weighted_5-utr.txt', 'w') do |fw|
  framework.output_all_5utr(genes_to_extract, fw) do |output_stream, gene_info, transcript_group, peaks_info, expression, spliced_sequence, spliced_cages|
    output_stream.puts ">#{gene_info}\t#{transcript_group}\t#{expression}"
    output_stream.puts spliced_sequence
  end
end

File.open('weighted_5-utr-polyN-masked.txt', 'w') do |fw|
  framework.output_all_5utr(genes_to_extract, fw) do |output_stream, gene_info, transcript_group, peaks_info, expression, spliced_sequence, spliced_cages|
    output_stream.puts ">#{gene_info}\t#{transcript_group}\t#{expression}"
    output_stream.puts mark_best_starts_as_poly_n(spliced_sequence, spliced_cages, 0.7)
  end
end