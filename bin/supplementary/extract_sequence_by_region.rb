require_relative '../../lib/intervals/genome_region'
require 'optparse'

tab_separated = false
print_positions = true
OptionParser.new do |opts|
  opts.banner = "Tool allows one to load sequence of the region in a genome. " +
                "Genome should be in a plain text without line breaks or FASTA > annotation string\n" +
                "No result reversing to be done for regions on negative strand\n" +
                "Usage: #{opts.program_name} <genome_folder> <region of interest> [options]\n"
  opts.separator "Options:"
  opts.on('--[no-]tab-separated', 'Output results with tabs between nucleotides (useful for pasting to tables') {|v| tab_separated = v }
  opts.on('--[no-]print-positions', 'Output position numbers above cage counts; works only with --tab-separated') {|v| print_positions = v }
end.parse!(ARGV)

genome_folder = ARGV[0]
annotation = ARGV[1]
region_of_interest = GenomeRegion.new_by_annotation(annotation)

sequence = region_of_interest.load_sequence(genome_folder)
if tab_separated
  puts region_of_interest.region.to_range.to_a.join("\t")  if print_positions
  puts sequence.each_char.to_a.join("\t")
else
  puts sequence
end
