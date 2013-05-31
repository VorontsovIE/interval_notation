$:.unshift File.join(File.dirname(File.expand_path(__FILE__)), 'lib')
require 'identificator_mapping'

# transcripts_after_splicing.txt  mTOR_mapping.txt
input_file, targets_filename = ARGV.first(2)

mtor_targets, translational_genes = read_mtor_mapping(targets_filename)

File.open(input_file) do |f|
  gene_infos = []
  f.each_line do |line|
    if line.start_with? '>'
      # dump previous transcript infos
      unless gene_infos.empty?
        hgnc_id = gene_infos.shift
        puts gene_infos.join if mtor_targets.has_key?(hgnc_id)
      end
      # started reading new transcript infos
      hgnc_id = line[1..-1].strip.split("\t").first.split(':').last.to_i
      gene_infos = [hgnc_id]
    end
    gene_infos << line
  end
end