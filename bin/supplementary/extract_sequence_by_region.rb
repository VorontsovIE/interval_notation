require_relative '../../lib/intervals/genome_region'

begin
annotation = ARGV[0]
genome_folder = ARGV[1]
region_of_interest = GenomeRegion.new_by_annotation(annotation)

puts region_of_interest.load_sequence(genome_folder)
rescue => e
  $stderr.puts "Annotation should be in format: chr1:1234..5678,+\n\n"
  $stderr.puts e
end
