$:.unshift File.dirname(File.expand_path(__FILE__))
require 'region'

# returns {strand => {chromosome => {position => num_reads} } } structure
def read_cages(input_file)
  cages = {'+' => {}, '-' => {}}
  File.open(input_file) do |f|
    f.each_line do |line|
      # chr1  564462  564463  chr1:564462..564463,+ 1 +
      # pos_end is always pos_start+1 because each line is reads from the single position
      chromosome, pos_start, pos_end, region_annotation, num_reads, strand = line.strip.split("\t")
      pos_start, pos_end, num_reads = pos_start.to_i, pos_end.to_i, num_reads.to_i
      cages[strand][chromosome] ||= {}
      cages[strand][chromosome][pos_start] = num_reads
    end
  end
  cages
end