require_relative '../../lib/intervals/genome_region'
require_relative '../../lib/cage'
require 'optparse'
require 'shellwords'
require 'zlib'

output_folder = 'out'
use_interval_suffix = true
OptionParser.new do |opts|
  opts.banner = "Tool allows one to cut only a region of interest from a bed file.\n" +
                "Usage: #{opts.program_name} <region of interest> <bed-files>... [options]\n" + 
                "         or\n" +
                "       list-of-bed-files | #{opts.program_name} <region of interest> [options]"
  opts.separator 'Options:'
  opts.on('--output-folder FOLDER') {|value| output_folder = value }
  opts.on('--[no-]interval-suffix') {|value| use_interval_suffix = value }
end.parse!(ARGV)

annotation = ARGV.shift
tissue_filenames = []
tissue_filenames += Shellwords.split($stdin.read)  unless $stdin.tty?
tissue_filenames += ARGV

region_of_interest = GenomeRegion.new_by_annotation(annotation)
region_str = region_of_interest.to_s.tr(':', ',')

Dir.mkdir(output_folder)  unless Dir.exist?(output_folder)

tissue_filenames.each do |tissue_filename|
  tissue = File.basename(tissue_filename).gsub(/\.bed(\.gz)?/, '')
  output_file_basename = use_interval_suffix ? "#{tissue}_#{region_str}.bed" : "#{tissue}.bed"
  output_filename = File.join(output_folder, output_file_basename)

  $stderr.puts "#{tissue_filename} --> #{output_filename}"

  File.open(output_filename, 'w') do |output_file|
    if File.extname(tissue_filename) == '.gz'
      select_cages_from(tissue_filename, output_file, region_of_interest, reader: Zlib::GzipReader)
    else
      select_cages_from(tissue_filename, output_file, region_of_interest, reader: File)
    end
  end
end
