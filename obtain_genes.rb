# We don't collect peaks that have zero expression

require 'logger'
$logger = Logger.new($stderr)

require_relative 'lib/gene_data_loader'

# cages_file = 'prostate%20cancer%20cell%20line%253aPC-3.CNhs11243.10439-106E7.hg19.ctss.bed'
# output_file = 'spliced_transcripts.txt'

cages_file, output_file = *ARGV
raise "You should specify file with cages for a specific tissue(*.bed) and output file" unless cages_file && output_file

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

File.open(output_file, 'w') do |fw|
  framework.output_all_5utr(framework.genes_to_process, fw)
end
