require_relative '../../lib/intervals/genome_region'
require 'zlib'

# annotation = ARGV[0]
# tissues_filename = ARGV[1]
annotation = 'chr1:160579800-160617200,-'
tissues_filename = 'tissue_names.txt'
region_of_interest = GenomeRegion.new_by_annotation(annotation)


def each_cage_line_from_stream(stream)
  stream.each_line do |line|
    chromosome, pos_start, _pos_end, region_annotation, num_reads, strand = line.chomp.split("\t")
    strand = strand.to_sym
    chromosome = chromosome.to_sym
    pos_start, num_reads = pos_start.to_i, num_reads.to_i
    yield line, GenomeRegion.new_by_annotation(region_annotation), num_reads
  end
end

def select_cages_from_gzip_to(gzip_bed_filename, output_stream)
  Zlib::GzipReader.open(gzip_bed_filename) do |gz_f|
    each_cage_line_from_stream(gz_f) do |line, region, num_reads|
      output_stream.puts(line)  if region_of_interest.include?(region)
    end
  end
end


Dir.mkdir('out')  unless Dir.exist?('out')
tissues_filename.readlines(tissues_filename).each do |tissue|
  File.open(tissue_filename + '.out', 'w') do |output_file|
    select_cages_from_gzip_to(CGI.escape(tissue) + '.hg19.ctss.bed', File.join('out', tissue + '.txt'))
  end
end
