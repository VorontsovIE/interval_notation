require_relative '../../lib/intervals/genome_region'
require 'shellwords'
require 'zlib'

# annotation = ARGV.shift
# tissues_filename = ARGV[0]
annotation = 'chr1:160579800..160617200,-'
# tissues_filename = 'tissue_names.txt'
region_of_interest = GenomeRegion.new_by_annotation(annotation)

# p region_of_interest.intersect?(GenomeRegion.new_by_annotation('chr1:160579801..160617199,-'))

def each_cage_line_from_stream(stream)
  stream.each_line do |line|
    chromosome, pos_start, _pos_end, region_annotation, num_reads, strand = line.chomp.split("\t")
    strand = strand.to_sym
    chromosome = chromosome.to_sym
    pos_start, num_reads = pos_start.to_i, num_reads.to_i
    yield line, GenomeRegion.new_by_annotation(region_annotation), num_reads
  end
end

# reader: Zlib::GzipReader
def select_cages_from(gzip_bed_filename, output_stream, region_of_interest, reader: File)
  reader.open(gzip_bed_filename) do |gz_f|
    each_cage_line_from_stream(gz_f) do |line, region, num_reads|
      if region_of_interest.intersect?(region)
        output_stream.puts(line)
        $stderr.puts line, region, num_reads
      end
    end
  end
end


Dir.mkdir('out')  unless Dir.exist?('out')

Shellwords.split(ARGF.read).each do |tissue|
  tissue_filename = tissue # CGI.escape(tissue) + '.hg19.ctss.bed'
  output_filename = File.join('out', File.basename(tissue_filename) + '.out')
  File.open(output_filename, 'w') do |output_file|
    select_cages_from(tissue_filename, output_file, region_of_interest)
  end
end
