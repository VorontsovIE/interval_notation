require_relative '../../lib/cage'
require_relative '../../lib/intervals/genome_region'

# Usage:
#         ruby cut_cages.rb <region annotation> <cages bed gzip file> [options]
# Options:
#         --with-sequence <genome_folder> -- load sequence for a given region and output it tab-separated
# Example: ruby cut_cages.rb chr1:100..500,+ pc-3.bed --with-sequence source_data/genome/hg19/
with_sequence = ARGV.index('--with-sequence')
if with_sequence
  genome_folder = ARGV.delete_at(with_sequence + 1)
  ARGV.delete_at(with_sequence)
end
annotation, gzip_bed_filename = ARGV.first(2)

cages = cages_initial_hash
read_cages_from_gzip_to(gzip_bed_filename, cages, nil)

region = GenomeRegion.new_by_annotation(annotation)
region_cages = region.load_cages(cages)
if with_sequence
  region_sequence = region.load_sequence(genome_folder)
  puts region_cages.join("\t")
  puts region_sequence.each_char.to_a.join("\t")
else
  puts region_cages.join("\t")
end
