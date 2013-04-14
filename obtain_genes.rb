# We don't collect peaks that have zero expression

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

# class Sequence
#   attr_reader :sequence, :markup
# end

# cages_file = 'prostate%20cancer%20cell%20line%253aPC-3.CNhs11243.10439-106E7.hg19.ctss.bed'
# output_file = 'spliced_transcripts.txt'

cages_file, output_file = *ARGV
raise "You should specify file with cages for a specific tissue(*.bed) and output file" unless cages_file && output_file

all_cages = read_cages(cages_file)
hgnc_to_entrezgene, entrezgene_to_hgnc = read_hgnc_entrezgene_mappings('HGNC_protein_coding_22032013_entrez.txt')
entrezgene_transcripts = read_entrezgene_transcript_ids('knownToLocusLink.txt')
all_peaks = Peak.peaks_from_file('robust_set.freeze1.reduced.pc-3', hgnc_to_entrezgene, entrezgene_to_hgnc)
genes = Gene.genes_from_file('HGNC_protein_coding_22032013_entrez.txt')
all_transcripts = Transcript.transcripts_from_file('knownGene.txt')

REGION_LENGTH = 100

genes_to_process = {}
genes.each do |hgnc_id, gene|
  $logger.warn "Skip #{gene}" and next  unless gene.collect_transcripts(entrezgene_transcripts, all_transcripts)
  $logger.warn "Skip #{gene}" and next  unless gene.collect_peaks(all_peaks)
  genes_to_process[hgnc_id] = gene
end


# We count all gene with the same UTR as the same transcript group and doesn't
# renormalize expression and other quantities by number of transcripts in a group,
# because have not enough information about concrete transcripts in a group.

transcript_groups = {}
genes_to_process.each do |hgnc_id, gene|
  transcript_groups[hgnc_id] = gene.transcripts_grouped_by_common_exon_structure_on_utr(REGION_LENGTH)
end

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



File.open(output_file, 'w') do |fw|
  genes_to_process.each do |hgnc_id, gene|
    transcript_groups[hgnc_id].each do |transcript_group|
      utr = transcript_group.utr
      exons_on_utr = transcript_group.exons_on_utr

      # sequence and cages here are unreversed on '-'-strand. One should possibly reverse both arrays and complement sequence
      cages = utr.load_cages(all_cages)
      sequence = utr.load_sequence('genome/hg19/')

      # all transcripts in the group have the same associated peaks
      associated_peaks = transcript_group.associated_peaks

      summary_expression = transcript_group.summary_expression
      gene_info = "HGNC:#{gene.hgnc_id}\t#{gene.approved_symbol}\tentrezgene:#{gene.entrezgene_id}"
      peaks_info = associated_peaks.map{|peak| peak.region.to_s}.join(';')

      spliced_sequence = splice_sequence(sequence, utr, exons_on_utr)
      spliced_cages = splice_array(cages, utr, exons_on_utr)

      fw.puts ">#{gene_info}\t#{transcript_group}\t#{peaks_info}\t#{summary_expression}"
      #puts sequence
      #puts cages.join("\t")
      fw.puts spliced_sequence
      fw.puts spliced_cages.join("\t")
    end
  end
end