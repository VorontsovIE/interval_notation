input_file = 'log_.txt'

def percent_of_starts_matching_pattern(sequence, cages, pattern)
  sum_of_all_cages = cages.inject(0, &:+)
  sum_of_matching_cages = 0
  loop do
    match = pattern.match(sequence)
    raise StopIteration  unless match
    pos = match.begin(0)
    sum_of_matching_cages += cages[pos]
    sequence = sequence[pos+1 .. -1]
    cages = cages[pos+1 .. -1]
    raise StopIteration unless sequence
  end
  sum_of_all_cages != 0  ?  sum_of_matching_cages.to_f / sum_of_all_cages  :  nil
end

def median_expression(input_file)
  expression_array = []
  File.open(input_file) do |f|
    line_iterator = f.each_line
    loop do
      hgnc_id, approved_symbol, entrezgene_id, \
      utr, exon_structure_on_utr_info, transcripts_info, \
      peaks_info, expression = line_iterator.next.strip[1..-1].split("\t")
      line_iterator.next
      line_iterator.next
      expression_array << expression.to_f
    end
  end
  expression_array.sort[expression_array.size / 2]
end

def genes_relevant(input_file)
  File.readlines(input_file)[1..-1].map(&:strip).reject(&:empty?).map{|line| line.split(' ').last.split(':').last }
end

p median_expression = median_expression(input_file)
relevant_genes = genes_relevant('gene_cart.csv')

summary_matching_rate = {}
sum_expr = {}
gene_names = {}
gene_expression = {}
File.open(input_file) do |f|
  line_iterator = f.each_line
  loop do
    hgnc_id, approved_symbol, entrezgene_id, \
    utr, exon_structure_on_utr_info, transcripts_info, \
    peaks_info, expression = line_iterator.next.strip[1..-1].split("\t")

    hgnc_id = hgnc_id.split(':').last
    expression = expression.to_f
    transcripts = transcripts_info.split(';')

    sum_expr[hgnc_id] ||= 0
    sum_expr[hgnc_id] += expression

    sequence = line_iterator.next.strip
    cages = line_iterator.next.split("\t").map(&:to_i)
    
    summary_matching_rate[hgnc_id] ||= 0
    matching_rate = percent_of_starts_matching_pattern(sequence, cages, /[CT]{5,}/i) || 0
    summary_matching_rate[hgnc_id] += expression * matching_rate

    gene_names[hgnc_id] = approved_symbol
    gene_expression[hgnc_id] = expression
    puts "HGNC:#{hgnc_id}\t#{transcripts_info}\t#{expression}\t#{matching_rate}"
  end
end

puts '==================='
genes = gene_names.keys
genes.each do |hgnc_id|
  if true # gene_expression[hgnc_id] >= median_expression
    matching_rate = summary_matching_rate[hgnc_id].to_f / sum_expr[hgnc_id]
    puts "HGNC:#{hgnc_id}#{relevant_genes.include?(hgnc_id) ? '*' : ''}\t#{gene_names[hgnc_id]}\t#{gene_expression[hgnc_id]}\t#{matching_rate}"
  end
end