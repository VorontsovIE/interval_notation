def read_mtor_carting(input_file)
  mtor_targets = {}
  translational_genes = {}
  File.open(input_file) do |f|
    f.each_line do |line|
      next if f.lineno == 1
      hsieh_name, hgnc_name, hgnc_id = line.strip.split("\t")
      hgnc_id = hgnc_id.split(':').last
      mtor_targets[hgnc_id] = hgnc_name
      translational_genes[hgnc_id] = hgnc_name  if hsieh_name.end_with?('=')
    end
  end
  return mtor_targets, translational_genes
end

def percent_of_starts_matching_pattern(sequence, cages, pattern)
  sum_of_all_cages = cages.inject(0, &:+)
  sum_of_matching_cages = 0
  loop do
    match = sequence.match(pattern)
    raise StopIteration  unless match
    pos = match.begin(0)
    sum_of_matching_cages += cages[pos]
    sequence = sequence[pos+1 .. -1]
    cages = cages[pos+1 .. -1]
    raise StopIteration  unless sequence
  end
  sum_of_all_cages != 0  ?  sum_of_matching_cages.to_f / sum_of_all_cages  :  nil
end

mtor_targets, translational_genes = read_mtor_carting("mTOR_carting.txt")
input_file = 'log_.txt'

gene_names = {}
gene_expression = {}
gene_matching_rna_pool = {}

File.open('transcript_matching_rates.out', 'w') do |fw|
  File.open(input_file) do |f|
    line_iterator = f.each_line
    loop do
      line_infos = line_iterator.next.strip[1..-1] # remove '>'
      sequence = line_iterator.next.strip
      cages = line_iterator.next.split("\t").map(&:to_i)
      
      hgnc_id, approved_symbol, entrezgene_id, \
      utr, exon_structure_on_utr_info, transcripts_info, \
      peaks_info, expression = line_infos.split("\t")

      hgnc_id = hgnc_id.split(':').last
      expression = expression.to_f
      gene_names[hgnc_id] = approved_symbol
      
      matching_rate = percent_of_starts_matching_pattern(sequence, cages, /.{,5}[CT]{5,}/i) || 0
      
      gene_expression[hgnc_id] ||= 0
      gene_matching_rna_pool[hgnc_id] ||= 0
      gene_expression[hgnc_id] += expression
      gene_matching_rna_pool[hgnc_id] += expression * matching_rate
      
      is_mtor_target = mtor_targets[hgnc_id] ? '*mTOR-target*' : ''
      is_translational_gene = translational_genes[hgnc_id] ? '*translational-gene*' : ''
      fw.puts "HGNC:#{hgnc_id}\t#{gene_names[hgnc_id]}\t#{transcripts_info}\t#{expression}\t#{matching_rate}\t#{is_mtor_target}\t#{is_translational_gene}"
    end
  end
end


gene_matching_rate = {}
genes = gene_names.keys
File.open('gene_matching_rates.out', 'w') do |fw|
  genes.each do |hgnc_id|
    gene_matching_rate[hgnc_id] = gene_matching_rna_pool[hgnc_id].to_f / gene_expression[hgnc_id]

    is_mtor_target = mtor_targets[hgnc_id] ? '*mTOR-target*' : ''
    is_translational_gene = translational_genes[hgnc_id] ? '*translational-gene*' : ''
    fw.puts "HGNC:#{hgnc_id}\t#{gene_names[hgnc_id]}\t#{gene_expression[hgnc_id]}\t#{gene_matching_rate[hgnc_id]}\t#{is_mtor_target}\t#{is_translational_gene}"
  end
end
