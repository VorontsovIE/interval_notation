# We don't collect peaks that have zero expression

require 'logger'
$logger = Logger.new($stderr)

$:.unshift File.join(File.dirname(File.expand_path(__FILE__)), 'lib')
require 'gene_data_loader_fantom_wo_peaks'

# class Sequence
#   attr_reader :sequence, :markup
# end

# cages_file = 'prostate%20cancer%20cell%20line%253aPC-3.CNhs11243.10439-106E7.hg19.ctss.bed'
# output_file = 'spliced_transcripts.txt'

#cages_file, output_file = *ARGV
#raise "You should specify file with cages for a specific tissue(*.bed) and output file" unless cages_file && output_file

Dir.glob('for_article/source_data/fantom_cage_files/*.bed').each do |cages_file|
  framework = GeneDataLoaderWithoutPeaks.new(cages_file, 'for_article/source_data/protein_coding_27_05_2013.txt', 'for_article/source_data/knownToLocusLink_hg18.txt', 'for_article/source_data/knownGene_hg18.txt', 100)
  cages_filename = File.basename(cages_file, File.extname(cages_file))

  File.open('for_article/results/' + cages_filename.sub(/\.bed$/,'.txt'), 'w') do |fw|
    framework.output_all_5utr(framework.genes_to_process, fw)
  end
end
