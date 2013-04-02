# We don't collect peaks that have zero expression

# TODO:
# 1) Some genes hasn't entrez in mapping but has it in fantom table
# For genes that has no mapping we get mapping from fantom
# 2) Extract gene expression calculation into its own method
# 3) Class Sequence which will be able to store sequence(possibly with gaps) and its markup
# It makes sense for iterating elements of sequence. Splicing should be moved in that class
# 4) Extract all identificator mappings into its own class which would also control logic of rejecting data
# 5) TranscriptGroup should encapsulate expression calculation. 
# Before that it's useful to renorm peaks according to number of genes containing it in a separate method
# 6) Add support for work with peaks-info file for all tissues

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
transcript_groups = {}
number_of_genes_for_a_peak = {} # number of genes that have peak in their transcript UTRs.
genes.each do |hgnc_id, gene|
  $logger.warn "Skip #{gene}" and next  unless gene.collect_transcripts(entrezgene_transcripts, all_transcripts)
  $logger.warn "Skip #{gene}" and next  unless gene.collect_peaks(all_peaks)
  genes_to_process[hgnc_id] = gene
end

genes_to_process.each do |hgnc_id, gene|
  transcript_groups[hgnc_id] = gene.transcripts_grouped_by_common_exon_structure_on_utr(REGION_LENGTH)

  peaks_associated_to_gene = transcript_groups[hgnc_id].map{|transcript_group|
    transcript_group.peaks_associated(gene.peaks, REGION_LENGTH)
  }.flatten.uniq
  
  peaks_associated_to_gene.each do |peak|
    number_of_genes_for_a_peak[peak] ||= 0
    number_of_genes_for_a_peak[peak] += 1
  end
end

File.open(output_file, 'w') do |fw|
  genes_to_process.each do |hgnc_id, gene|  
    transcript_groups[hgnc_id].each do |transcript_group|
      utr = transcript_group.utr
      exons_on_utr = transcript_group.exons_on_utr
      transcripts = transcript_group.transcripts

      # sequence and cages here are unreversed on '-'-strand. One should reverse both arrays and complement sequence
      cages = collect_cages(all_cages, utr)
      sequence = utr.load_sequence('genome/hg19/')
      # all transcripts in the group have the same associated peaks
      associated_peaks = transcript_group.peaks_associated(gene.peaks, REGION_LENGTH)
    
      summary_expression = associated_peaks.map{|peak| 
        num_of_transcript_groups_associated_to_peak = transcript_groups[hgnc_id].count{|transcript_group_2|
          transcript_group_2.peaks_associated(gene.peaks, REGION_LENGTH).include?(peak)
        }
        # Divide expression of each peak equally between genes and then for each gene between glued transcripts
        # Each peak can affect different transcripts so we distribute its expression equally
        # between all transcripts of a single gene whose expression can be affected by this peak
        (peak.tpm.to_f / number_of_genes_for_a_peak[peak]) / num_of_transcript_groups_associated_to_peak
      }.inject(&:+)
      
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