require 'optparse'
require_relative '../../lib/cage'
require_relative '../../lib/intervals/genome_region'

# Usage:
#         ruby cut_cages.rb <region annotation> <cages bed gzip file> [options]
# Options:
#         --with-sequence <genome_folder> -- load sequence for a given region and output it tab-separated
# Example: ruby cut_cages.rb chr1:100..500,+ pc-3.bed --with-sequence source_data/genome/hg19/

with_sequence = false
genome_folder = nil
OptionParser.new do |opts|
  opts.on('--with-sequence GENOME_DIR', "load sequence for a given region and output it tab-separated"){|value|
    with_sequence = true
    genome_folder = value
  }
end.parse!(ARGV)

bed_filename, annotation = ARGV.first(2)

cages = cages_initial_hash
read_cages_from_file_to(bed_filename, cages, nil)

region = GenomeRegion.new_by_annotation(annotation)
region_cages = region.load_cages(cages)

if with_sequence
  region_sequence = region.load_sequence(genome_folder)
  puts region_cages.join("\t")
  puts region_sequence.each_char.to_a.join("\t")
else
  puts region_cages.join("\t")
end