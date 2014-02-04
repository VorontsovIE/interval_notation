require_relative 'lib/identificator_mapping'

# output only non-targets
invert_selection = ARGV.delete('--invert-selection')

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
        if !!mtor_targets.has_key?(hgnc_id) ^ !!invert_selection
          puts gene_infos.join
        end
      end
      # started reading new transcript infos
      hgnc_id = line[1..-1].strip.split("\t").first.split(':').last.to_i
      gene_infos = [hgnc_id]
    end
    gene_infos << line
  end
end
