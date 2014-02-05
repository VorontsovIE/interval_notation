# TODO:
# 1) We should also match motifs
# 2) extract matching_rates in calculate_transcript_matching_rates from transcript_info.
# It's a bed smell that we rewrite it on each iteration
# 3) Think careful about filtering by minimal expression. There're at least two cases:
# - choose minimal expression of gene to treat it as significant
# In this case we'll lose such genes as RPL9 which are expressed mRNA slow but synthesis of proteins goes effective.
# - normalize expression of each gene by maximal expression (or expressions_by_tissue.sort.last(10).average) of this gene through tissues
# we suggest that a peak'll be expressed at least in a single tissue, so we'll understand whether gene(a peak of gene) is expressed or not
# in this particular tissue
# 4) Extract rate evaluators to classes to encapsulate caching results and so on
# 5) fix scoring N in Bioinform::PWM (should it be average of all scores or weighted average or smth different)
#
# 6) Add poly-N head of length about 10nt to RNA transcript in order to be able to work with motifs with biased start
#

$:.unshift '../../lib'
require 'matching_rate'
require 'classifier_quality'
require 'identificator_mapping'

def read_transcript_infos(input_file)
  transcript_infos = []
  File.open(input_file) do |f|
    line_iterator = f.each_line
    loop do
      line_infos = line_iterator.next.strip[1..-1] # remove '>'
      sequence = line_iterator.next.strip
      cages = line_iterator.next.split("\t").map(&:to_i)

      hgnc_id, approved_symbol, entrezgene_id, \
      utr, exon_structure_on_utr_info, transcripts_names, \
      peaks_info, expression = line_infos.split("\t")

      hgnc_id = hgnc_from_string(hgnc_id)
      entrezgene_id = entrezgene_id.to_i
      expression = expression.to_f
      transcript_infos << {hgnc_id: hgnc_id, name: approved_symbol,
                          transcript_names: transcripts_names, expression: expression,
                          sequence: sequence, cages: cages}
    end
  end
  transcript_infos
end

def print_transcript_matching_rates_infos(output_file, transcript_infos, mtor_targets, translational_genes)
  File.open(output_file, 'w') do |fw|
    transcript_infos.each do |transcript_info|
      hgnc_id = transcript_info[:hgnc_id]
      transcript_names = transcript_info[:transcript_names]
      expression = transcript_info[:expression]
      matching_rate = transcript_info[:matching_rate]
      gene_name = transcript_info[:name]

      is_mtor_target = mtor_targets[hgnc_id] ? '*mTOR-target*' : ''
      is_translational_gene = translational_genes[hgnc_id] ? '*translational-gene*' : ''
      fw.puts "HGNC:#{hgnc_id}\t#{gene_name}\t#{transcript_names}\t#{expression}\t#{matching_rate}\t#{is_mtor_target}\t#{is_translational_gene}"
    end
  end
end

def print_gene_matching_rates_infos(output_file, gene_names, gene_expression, gene_matching_rate, mtor_targets, translational_genes)
  File.open(output_file, 'w') do |fw|
    gene_names.each do |hgnc_id, name|
      expression = gene_expression[hgnc_id]
      matching_rate = gene_matching_rate[hgnc_id]
      is_mtor_target = mtor_targets[hgnc_id] ? '*mTOR-target*' : ''
      is_translational_gene = translational_genes[hgnc_id] ? '*translational-gene*' : ''
      fw.puts "HGNC:#{hgnc_id}\t#{name}\t#{expression}\t#{matching_rate}\t#{is_mtor_target}\t#{is_translational_gene}"
    end
  end
end


def collect_gene_names(transcript_infos)
  gene_names = {}
  transcript_infos.each do |transcript_info|
    hgnc_id = transcript_info[:hgnc_id]
    gene_names[ hgnc_id ] = transcript_info[:name]
  end
  gene_names
end

def collect_gene_expression(transcript_infos)
  gene_expression = {}
  transcript_infos.each do |transcript_info|
    hgnc_id = transcript_info[:hgnc_id]
    gene_expression[hgnc_id] ||= 0
    gene_expression[hgnc_id] += transcript_info[:expression]
  end
  gene_expression
end

def calculate_transcript_matching_rates_for_ct_saturation_in_window(transcript_infos, max_distance_from_start, window_size, min_ct_saturation)
  transcript_infos.each do |transcript_info|
    sequence = transcript_info[:sequence]
    cages = transcript_info[:cages]
    transcript_info[:cumulative_ct_saturation] ||= cumulative_saturation(sequence, ['C', 'T'])
    cumulative_ct_saturation = transcript_info[:cumulative_ct_saturation]
    transcript_info[:windows_saturations] ||= []
    transcript_info[:windows_saturations][window_size] ||= windows_saturations(sequence, window_size, cumulative_ct_saturation)
    windows_saturations = transcript_info[:windows_saturations][window_size]

    #matching_rate = percent_of_starts_matching_pattern(sequence, cages, /[CT]+/i, max_distance_from_start, min_length) || 0
    matching_rate = percent_of_starts_by_ct_saturation(sequence, cages, windows_saturations,
                                                      max_distance_from_start, window_size, min_ct_saturation) || 0
    transcript_info[:matching_rate] = matching_rate
  end
  transcript_infos
end

def calculate_transcript_matching_rates_for_motif(transcript_infos, max_distance_from_start, pwm, threshold)
  transcript_infos.each do |transcript_info|
    sequence = transcript_info[:sequence]
    cages = transcript_info[:cages]

    positions = 0..(sequence.length - pwm.length)
    transcript_info[:match_at_position] ||= positions.map{|pos| pwm.score(sequence[pos, pwm.length]) >= threshold ? true : nil}
    matching_rate = percent_of_starts_matching_motif(sequence.length, cages, max_distance_from_start, transcript_info[:match_at_position]) || 0

    transcript_info[:matching_rate] = matching_rate
  end
  transcript_infos
end


# transcript_info for each transcript should have calculated matching rate.
def gene_matching_rate(transcript_infos, gene_expression)
  rna_pool_matching_rate_unnormalized = {}
  transcript_infos.each do |transcript_info|
    raise 'Calculate transcript matching rates first' unless transcript_info.has_key?(:matching_rate)
    hgnc_id = transcript_info[:hgnc_id]
    rna_pool_matching_rate_unnormalized[hgnc_id] ||= 0
    rna_pool_matching_rate_unnormalized[hgnc_id] += transcript_info[:expression] * transcript_info[:matching_rate]
  end

  gene_ids = rna_pool_matching_rate_unnormalized.keys
  Hash[
    gene_ids.map{|hgnc_id|
      [hgnc_id, rna_pool_matching_rate_unnormalized[hgnc_id].to_f / gene_expression[hgnc_id]]
    }
  ]
end


def percent_of_starts_matching_motif_pos(len, cages, distance_from_start, match_at_position)
  positions = 0...len
  sum_of_all_cages = cages.inject(0, &:+)
  sum_of_matching_cages = 0
  positions.each{|pos|
    sum_of_matching_cages += cages[pos]  if (pos - distance_from_start >= 0 && match_at_position[pos - distance_from_start])
  }
  (sum_of_all_cages != 0)  ?  sum_of_matching_cages.to_f / sum_of_all_cages  :  nil
end

POLY_N_SEQ = 'N'*10
POLY_N_CAGES = [0]*10

def calculate_transcript_matching_rates_for_motif_pos(transcript_infos, max_distance_from_start, pwm, threshold)
  transcript_infos.each do |transcript_info|
    sequence = transcript_info[:sequence] + POLY_N_SEQ
    cages = transcript_info[:cages] + POLY_N_CAGES

    positions = 0..(sequence.length - pwm.length)
    transcript_info[:match_at_position] ||= positions.map{|pos| pwm.score(sequence[pos, pwm.length]) >= threshold ? true : nil}
    matching_rate = percent_of_starts_matching_motif_pos(sequence.length, cages, max_distance_from_start, transcript_info[:match_at_position]) || 0

    transcript_info[:matching_rate] = matching_rate
  end
  transcript_infos
end



#max_distance_from_start, min_length = ARGV.first(2).map(&:to_i)
#raise 'Specify max_distance_from_start and min_length as command-line args' unless max_distance_from_start && min_length

#raise 'Incorrect number of command-line arguments' unless ARGV.size == 3
#max_distance_from_start, window_size, min_ct_saturation =  ARGV.map(&:to_i)
#raise 'Specify max_distance_from_start and window_size and min_ct_saturation as command-line args' unless max_distance_from_start && window_size && min_ct_saturation

mtor_targets, translational_genes = read_mtor_mapping("mTOR_mapping.txt")
transcript_infos = read_transcript_infos('transcripts_after_splicing.txt')
gene_names = collect_gene_names(transcript_infos)
gene_expression = collect_gene_expression(transcript_infos)

pwm = Bioinform::PWM.new(File.read('top_motif/longest_5-utr_10.xml.pat'))
threshold = 1.04538 #4.74935
#(0..10).each do |max_distance_from_start|

  distance_from_start = 3
  calculate_transcript_matching_rates_for_motif_pos(transcript_infos, distance_from_start, pwm, threshold)

  gene_matching_rate = gene_matching_rate(transcript_infos, gene_expression)

  roc_points = roc_curve(gene_matching_rate, mtor_targets)
  auc = area_under_curve(roc_points)
  puts "#{distance_from_start}\t#{auc}"

  output_curve_data('roc.txt', roc_points)
  print_transcript_matching_rates_infos('transcript_matching_rates.out', transcript_infos, mtor_targets, translational_genes)
  print_gene_matching_rates_infos('gene_matching_rates.out', gene_names, gene_expression, gene_matching_rate, mtor_targets, translational_genes)
#end



=begin

(0..10).each do |max_distance_from_start|
  (1..10).each do |window_size|
    (0..window_size).each do |min_ct_saturation|

      calculate_transcript_matching_rates_for_ct_saturation_in_window(transcript_infos, max_distance_from_start, window_size, min_ct_saturation)
      gene_matching_rate = gene_matching_rate(transcript_infos, gene_expression)

      roc_points = roc_curve(gene_matching_rate, mtor_targets)
      auc = area_under_curve(roc_points)
      puts "#{max_distance_from_start}\t#{window_size}\t#{min_ct_saturation}\t#{auc}"

      output_curve_data('roc.txt', roc_points)
      # print_transcript_matching_rates_infos('transcript_matching_rates.out', transcript_infos, mtor_targets, translational_genes)
      # print_gene_matching_rates_infos('gene_matching_rates.out', gene_names, gene_expression, gene_matching_rate, mtor_targets, translational_genes)
    end
  end
end

=end

=begin
pwm = Bioinform::PWM.new(File.read('top_motif/longest_5-utr_10.xml.pat'))
threshold = 5.66224

distribution_count_motif_dist_from_max_peak = Hash.new{|hsh,key| hsh[key] = 0}
distribution_expression_motif_dist_from_max_peak = Hash.new{|hsh,key| hsh[key] = 0}
distribution_expression_unnormalized_motif_dist_from_max_peak = Hash.new{|hsh,key| hsh[key] = 0}

transcript_infos.each do |transcript_info|
  next unless  mtor_targets.has_key?(transcript_info[:hgnc_id])
  sequence = transcript_info[:sequence]
  cages = transcript_info[:cages]
  pos_of_max_peak = cages.each_with_index.max_by{|v, pos| v}.last

  positions = 0..(sequence.length - pwm.length)
  pos_of_best_match = positions.max_by{|pos| pwm.score(sequence[pos, pwm.length]) }
  next  unless pos_of_max_peak && pos_of_best_match

  distribution_count_motif_dist_from_max_peak[pos_of_best_match - pos_of_max_peak] += 1
  distribution_expression_motif_dist_from_max_peak[pos_of_best_match - pos_of_max_peak] += transcript_info[:expression].to_f / gene_expression[transcript_info[:hgnc_id]]
  distribution_expression_unnormalized_motif_dist_from_max_peak[pos_of_best_match - pos_of_max_peak] += transcript_info[:expression].to_f
end
File.open('count_distribution.txt','w'){|f|
  distribution_count_motif_dist_from_max_peak.sort_by{|k,v| k}.each{|k,v| f.puts "#{k}\t#{v}"}
}
File.open('expression_distribution.txt','w'){|f|
  distribution_expression_motif_dist_from_max_peak.sort_by{|k,v| k}.each{|k,v| f.puts "#{k}\t#{v}"}
}
File.open('expression_distribution_unnormalized.txt','w'){|f|
  distribution_expression_unnormalized_motif_dist_from_max_peak.sort_by{|k,v| k}.each{|k,v| f.puts "#{k}\t#{v}"}
}
=end
