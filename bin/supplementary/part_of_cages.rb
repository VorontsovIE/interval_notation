require_relative '../../lib/intervals/genome_region'
require 'shellwords'
require 'zlib'

def each_cage_line_from_stream(stream, chr)
  chr = "#{chr}\t"
  stream.each_line.lazy.select do |line|
    line.start_with?(chr)
  end.each do |line|
    yield line, GenomeRegion.new_by_bed_line(line)
  end
end

# reader: Zlib::GzipReader
def select_cages_from(gzip_bed_filename, output_stream, region_of_interest, reader: File)
  reader.open(gzip_bed_filename) do |gz_f|
    each_cage_line_from_stream(gz_f, region_of_interest.chromosome) do |line, region|
      if region_of_interest.intersect?(region)
        output_stream.puts(line)
      end
    end
  end
end

annotation = ARGV.shift
tissue_filenames = []
tissue_filenames += Shellwords.split($stdin.read)  unless $stdin.tty?
tissue_filenames += ARGV

# tissues_filename = ARGV[0]
# annotation = 'chr1:160579800..160617200,-'
# tissues_filename = 'tissue_names.txt'
region_of_interest = GenomeRegion.new_by_annotation(annotation)
region_str = "#{region_of_interest.chromosome},#{region_of_interest.region.pos_start}..#{region_of_interest.region.pos_end},#{region_of_interest.strand}"

# p region_of_interest.intersect?(GenomeRegion.new_by_annotation('chr1:160579801..160617199,-'))


Dir.mkdir('out')  unless Dir.exist?('out')

tissue_filenames.each do |tissue_filename|
  tissue = File.basename(tissue_filename).gsub(/\.bed(\.gz)?/, '') # CGI.escape(tissue) + '.hg19.ctss.bed'
  output_filename = File.join('out', tissue + '_' +  region_str + '.txt')
  $stderr.puts "#{tissue_filename}\t-->\t#{output_filename}"
  File.open(output_filename, 'w') do |output_file|
    if File.extname(tissue_filename) == '.gz'
      select_cages_from(tissue_filename, output_file, region_of_interest, reader: Zlib::GzipReader)
    else
      select_cages_from(tissue_filename, output_file, region_of_interest, reader: File)
    end
  end
end
