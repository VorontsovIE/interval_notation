require 'logger'
$logger = Logger.new($stderr)

$:.unshift File.join(File.dirname(File.expand_path(__FILE__)), 'lib')
require 'region'
require 'transcript'
require 'gene'
require 'peak'
require 'splicing'
require 'cage'
require 'identificator_mapping'
require 'transcript_group'

cages_file = 'prostate%20cancer%20cell%20line%253aPC-3.CNhs11243.10439-106E7.hg19.ctss.bed'

all_cages = read_cages(cages_file)
hgnc_to_entrezgene, entrezgene_to_hgnc = read_hgnc_entrezgene_mappings('HGNC_protein_coding_22032013_entrez.txt')
entrezgene_transcripts = read_entrezgene_transcript_ids('knownToLocusLink.txt')
all_peaks = Peak.peaks_from_file('robust_set.freeze1.reduced.pc-3', hgnc_to_entrezgene, entrezgene_to_hgnc)
genes = Gene.genes_from_file('HGNC_protein_coding_22032013_entrez.txt')
all_transcripts = Transcript.transcripts_from_file('knownGene.txt')
mtor_targets, translational_genes = read_mtor_mapping('mTOR_mapping.txt')

REGION_LENGTH = 100

genes_to_process = {}
genes.each do |hgnc_id, gene|
  $logger.warn "Skip #{gene}" and next  unless gene.collect_transcripts(entrezgene_transcripts, all_transcripts)
  $logger.warn "Skip #{gene}" and next  unless gene.collect_peaks(all_peaks)
  genes_to_process[hgnc_id] = gene
end

transcript_groups = {}
genes_to_process.each do |hgnc_id, gene|
  transcript_groups[hgnc_id] = gene.transcripts_grouped_by_common_exon_structure_on_utr(REGION_LENGTH)
end

###############################################

# At this stage we don't consider number of transcripts for a gene because
# we don't know anything about expression of each transcript for a gene.
number_of_genes_for_a_peak = Peak.calculate_number_of_genes_for_a_peak(genes_to_process, transcript_groups)

# Each peak can affect different transcripts so we distribute its expression
# first equally between all genes whose expression can be affected by this peak
# and then equally between all transcript groups of that gene

genes_to_process.each do |hgnc_id, gene|
  transcript_groups[hgnc_id].each do |transcript_group|
    peaks_expression = transcript_group.associated_peaks.map{|peak|
      num_of_transcript_groups_associated_to_peak = transcript_groups[hgnc_id].count{|transcript_group_2| transcript_group_2.associated_peaks.include?(peak) }
      (peak.tpm.to_f / number_of_genes_for_a_peak[peak]) / num_of_transcript_groups_associated_to_peak
    }

    transcript_group.summary_expression = peaks_expression.inject(&:+)
  end
end

# marks best start (top `rate` part of them) with poly-N so that motif finding ignore them
def mark_best_starts_as_poly_n(sequence, cages, rate)
  new_sequence = sequence.dup
  sum_cages = cages.inject(&:+)
  cages_taken = 0
  cages_sorted = cages.each_with_index.sort_by{|cage, index| cage}.reverse
  while cages_taken + cages_sorted.first.first <= sum_cages * 0.7
    cage, index = cages_sorted.shift
    cages_taken += cage
    new_sequence[index] = 'N'
  end
  new_sequence
end

genes_to_extract = genes_to_process.select{|hgnc_id, gene| mtor_targets.has_key?(hgnc_id)}

File.open('weighted_5-utr.txt', 'w') do |fw|
  genes_to_extract.each do |hgnc_id, gene|
    gene_expression = transcript_groups[hgnc_id].map(&:summary_expression).inject(&:+).to_f
    transcript_groups[hgnc_id].each do |transcript_group|
      utr = transcript_group.utr
      exons_on_utr = transcript_group.exons_on_utr

      spliced_sequence = splice_sequence(utr.load_sequence('genome/hg19/'), utr, exons_on_utr)
      spliced_cages = splice_array(collect_cages(all_cages, utr), utr, exons_on_utr)
      sequence_with_polyN_starts = mark_best_starts_as_poly_n(spliced_sequence, spliced_cages, 0.7)
      transcript_rate = transcript_group.summary_expression.to_f / gene_expression
      sequence, cages = sequence_with_polyN_starts, spliced_cages
      fw.puts ">#{sequence.length}\t#{hgnc_id}\t#{transcript_group}\t#{transcript_rate}\n#{sequence}\n#{cages.join ' '}"
      #fw.puts ">#{transcript_rate}\n#{sequence}"
    end
  end
end

File.open('longest_5-utr.txt', 'w') do |fw|
  genes_to_extract.each do |hgnc_id, gene|

    transcript_group_long, longest_utr, cages = transcript_groups[hgnc_id].map{|transcript_group|
      utr = transcript_group.utr
      exons_on_utr = transcript_group.exons_on_utr

      spliced_sequence = splice_sequence(utr.load_sequence('genome/hg19/'), utr, exons_on_utr)
      spliced_cages = splice_array(collect_cages(all_cages, utr), utr, exons_on_utr)
      sequence_with_polyN_starts = mark_best_starts_as_poly_n(spliced_sequence, spliced_cages, 0.7)

      [transcript_group, sequence_with_polyN_starts, spliced_cages]
    }.max_by{|transcript_group, sequence, cages| sequence.length }
    fw.puts ">#{longest_utr.length}\t#{hgnc_id}\t#{transcript_group_long.transcripts}\t1.0\n#{longest_utr}\n#{cages.join ' '}"
    #fw.puts ">1.0\n#{longest_utr}"
  end
end
