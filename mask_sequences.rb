$:.unshift File.join(File.dirname(File.expand_path(__FILE__)), 'lib')
require 'gene_data_loader'
require 'splicing'

def mask_best_cages(fasta_file, window_semiwidth, rate)
  File.open(fasta_file) do |f|
    begin
      loop do
        infos = f.readline.strip[1..-1]
        cages = f.readline.strip[1..-1].split("\t").map(&:to_i)
        sequence = f.readline.strip
        puts ">#{infos}"
        puts mark_best_starts_as_poly_n(sequence, cages, rate, window_semiwidth)
      end
    rescue EOFError
    end
  end
end


fasta_file, window_semiwidth, rate = ARGV.first(3)
raise 'Specify fasta (with cages) file and motif file and threshold'  unless fasta_file && window_semiwidth && rate
window_semiwidth, rate = window_semiwidth.to_i, rate.to_f

mask_best_cages(fasta_file, window_semiwidth, rate)