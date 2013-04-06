# TODO:
# 1) We should also match motifs 
# 2) extract matching_rates in calculate_transcript_matching_rates from transcript_info.
# It's a bed smell that we rewrite it on each iteration

$:.unshift File.join(File.dirname(File.expand_path(__FILE__)), 'lib')
require 'matching_rate'
require 'classifier_quality'

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

def calculate_transcript_matching_rates(transcript_infos, max_distance_from_start, window_size, min_ct_saturation)
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



#max_distance_from_start, min_length = ARGV.first(2).map(&:to_i)
#raise 'Specify max_distance_from_start and min_length as command-line args' unless max_distance_from_start && min_length

#raise 'Incorrect number of command-line arguments' unless ARGV.size == 3
#max_distance_from_start, window_size, min_ct_saturation =  ARGV.map(&:to_i)
#raise 'Specify max_distance_from_start and window_size and min_ct_saturation as command-line args' unless max_distance_from_start && window_size && min_ct_saturation

mtor_targets, translational_genes = read_mtor_mapping("mTOR_mapping.txt")
transcript_infos = read_transcript_infos('transcripts_after_splicing.txt')
gene_names = collect_gene_names(transcript_infos)
gene_expression = collect_gene_expression(transcript_infos)

(0..10).each do |max_distance_from_start|
  (1..10).each do |window_size|
    (0..window_size).each do |min_ct_saturation|
      #max_distance_from_start, window_size, min_ct_saturation = 0,3,3

      calculate_transcript_matching_rates(transcript_infos, max_distance_from_start, window_size, min_ct_saturation)
      gene_matching_rate = gene_matching_rate(transcript_infos, gene_expression)

      roc_points = roc_curve(gene_matching_rate, mtor_targets)
      auc = area_under_curve(roc_points)
      puts "#{max_distance_from_start}\t#{window_size}\t#{min_ct_saturation}\t#{auc}"

      # File.open('transcript_matching_rates.out','w') do |fw|
      #   transcript_infos.each do |transcript_info|
      #     hgnc_id = transcript_info[:hgnc_id]
      #     transcript_names = transcript_info[:transcript_names]
      #     expression = transcript_info[:expression]
      #     matching_rate = transcript_info[:matching_rate]
      #     gene_name = transcript_info[:name]

      #     is_mtor_target = mtor_targets[hgnc_id] ? '*mTOR-target*' : ''
      #     is_translational_gene = translational_genes[hgnc_id] ? '*translational-gene*' : ''
      #     fw.puts "HGNC:#{hgnc_id}\t#{gene_name}\t#{transcript_names}\t#{expression}\t#{matching_rate}\t#{is_mtor_target}\t#{is_translational_gene}"
      #   end
      # end

      # File.open('gene_matching_rates.out', 'w') do |fw|
      #   gene_names.each do |hgnc_id, name|
      #     expression = gene_expression[hgnc_id]
      #     matching_rate = gene_matching_rate[hgnc_id]
      #     is_mtor_target = mtor_targets[hgnc_id] ? '*mTOR-target*' : ''
      #     is_translational_gene = translational_genes[hgnc_id] ? '*translational-gene*' : ''
      #     fw.puts "HGNC:#{hgnc_id}\t#{name}\t#{expression}\t#{matching_rate}\t#{is_mtor_target}\t#{is_translational_gene}"
      #   end
      # end
    end
  end
end


