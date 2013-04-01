# We should also match motifs 

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

def percent_of_starts_matching_pattern(sequence, cages, pattern, max_distance_from_start, min_length)
  sum_of_all_cages = cages.inject(0, &:+)
  sum_of_matching_cages = 0
  complex_pattern = /(.{,#{max_distance_from_start}})(#{pattern})/i
  loop do
    match = sequence.match(complex_pattern)
    raise StopIteration  unless match
    pos = match.begin(0)
    sum_of_matching_cages += cages[pos] if match[2].length >= min_length
    sequence = sequence[pos+1 .. -1]
    cages = cages[pos+1 .. -1]
    raise StopIteration  unless sequence
  end
  sum_of_all_cages != 0  ?  sum_of_matching_cages.to_f / sum_of_all_cages  :  nil
end

def percent_of_starts_by_ct_saturation(sequence, cages, max_distance_from_start, window_size, min_ct_saturation)
  sum_of_all_cages = cages.inject(0, &:+)
  sum_of_matching_cages = 0
  
  # cumulative_ct_saturation is an array where each element(index) is number of CT-nucleotides in a region [0, index)
  cumulative_ct_saturation = Array.new(sequence.length + 1)
  cumulative_ct_saturation[0] = 0
  sequence.each_char.each_with_index do |letter, pos|
    cumulative_ct_saturation[pos+1] = cumulative_ct_saturation[pos] + (['C', 'T'].include?(letter.upcase) ? 1 : 0)
  end
  #max_distance_from_start.times {
  #  cumulative_ct_saturation[]
  #}

  sequence.length.times do |pos|
    windows_saturation = (0..max_distance_from_start).map{|dist_from_start|
      #sequence[pos + dist_from_start ... pos + dist_from_start + window_size].each_char.count{|x| x.downcase == 'c' || x.downcase == 't'}
      window_start = pos + dist_from_start
      window_end = pos + dist_from_start + window_size
      window_start = [window_start, sequence.length].min
      window_end = [window_end, sequence.length].min
      cumulative_ct_saturation[window_end] - cumulative_ct_saturation[window_start]
    }.max
    sum_of_matching_cages += cages[pos] if windows_saturation >= min_ct_saturation
  end
  sum_of_all_cages != 0  ?  sum_of_matching_cages.to_f / sum_of_all_cages  :  nil
end

# class MotifMatcher
# end

# class PatternMatcher
#   attr_accessor :pattern, :from_start, :min_length
#   attr_reader :current_position
#   def initialize(pattern, from_start, min_length)
#     @pattern, @from_start, @min_length = pattern, from_start, min_length
#     @current_position = 0
#   end
#   def match(sequence)
#     match = sequence[current_position..-1].match(pattern)
#     @current_position = match.begin(0) + 1
#   end
#   def each_match(sequence)
#     yield match while match = match(sequence)
#   end
# end

#max_distance_from_start, min_length = ARGV.first(2).map(&:to_i)
#raise 'Specify max_distance_from_start and min_length as command-line args' unless max_distance_from_start && min_length
raise 'Incorrect number of command-line arguments' unless ARGV.size == 3
max_distance_from_start, window_size, min_ct_saturation =  ARGV.map(&:to_i)
raise 'Specify max_distance_from_start and window_size and min_ct_saturation as command-line args' unless max_distance_from_start && window_size && min_ct_saturation

mtor_targets, translational_genes = read_mtor_carting("mTOR_mapping.txt")
input_file = 'transcripts_after_splicing.out'

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
      
      #matching_rate = percent_of_starts_matching_pattern(sequence, cages, /[CT]+/i, max_distance_from_start, min_length) || 0
      matching_rate = percent_of_starts_by_ct_saturation(sequence, cages, max_distance_from_start, window_size, min_ct_saturation) || 0
      
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
