$:.unshift File.join(File.dirname(File.expand_path(__FILE__)), 'lib')
require 'identificator_mapping'
require 'bioinform'
require 'classifier_quality'

module Bioinform
  class PWM
    def score(word)
      word = word.upcase
      raise ArgumentError, 'word in PWM#score(word) should have the same length as matrix'  unless word.length == length
      #raise ArgumentError, 'word in PWM#score(word) should have only ACGT-letters'  unless word.each_char.all?{|letter| %w{A C G T}.include? letter}
      (0...length).map do |pos|
        letter = word[pos]
        letter == 'N' ? matrix[pos].inject(&:+).to_f / 4 : matrix[pos][IndexByLetter[letter]]
      end.inject(&:+)
    end
  end
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

      hgnc_id = hgnc_id.split(':').last
      expression = expression.to_f
      transcript_infos << {hgnc_id: hgnc_id, name: approved_symbol,
                          transcript_names: transcripts_names, expression: expression,
                          sequence: sequence, cages: cages}
    end
  end
  transcript_infos
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


POLY_N_SEQ = 'N'*10
POLY_N_CAGES = [0]*10

def calculate_transcript_matching_rates_for_motif_pos(transcript_infos, max_distance_from_start, pwm, threshold)
  transcript_infos.each do |transcript_info|
    sequence = POLY_N_SEQ + transcript_info[:sequence]
    cages = POLY_N_CAGES + transcript_info[:cages]

    positions = 0..(sequence.length - pwm.length)
    transcript_info[:match_at_position] ||= positions.map{|pos| pwm.score(sequence[pos, pwm.length]) >= threshold ? true : nil}
    matching_rate = percent_of_starts_matching_motif_pos(sequence.length, cages, max_distance_from_start, transcript_info[:match_at_position]) || 0

    transcript_info[:matching_rate] = matching_rate
  end
  transcript_infos
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



mtor_targets, translational_genes = read_mtor_mapping("mTOR_mapping.txt")
transcript_infos = read_transcript_infos('transcripts_after_splicing.txt')
gene_names = collect_gene_names(transcript_infos)
gene_expression = collect_gene_expression(transcript_infos)

pwm = Bioinform::PWM.new(File.read('top_motif/longest_5-utr_10.xml.pat'))
threshold = 1.04538 #4.74935

distance_from_start = 3 # upstream direction
calculate_transcript_matching_rates_for_motif_pos(transcript_infos, distance_from_start, pwm, threshold)

gene_matching_rate = gene_matching_rate(transcript_infos, gene_expression)

roc_points = roc_curve(gene_matching_rate, mtor_targets)
auc = area_under_curve(roc_points)
puts "#{distance_from_start}\t#{auc}"

output_curve_data('roc.txt', roc_points)
print_transcript_matching_rates_infos('transcript_matching_rates.out', transcript_infos, mtor_targets, translational_genes)
print_gene_matching_rates_infos('gene_matching_rates.out', gene_names, gene_expression, gene_matching_rate, mtor_targets, translational_genes)
