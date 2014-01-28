# Extracting region -10;+10 around start of translation
# Splicing not taken into account

require 'logger'
$logger = Logger.new($stderr)

$:.unshift File.join(File.dirname(File.expand_path(__FILE__)), 'lib')
require 'intervals/genome_region'
require 'transcript'
require 'gene'
require 'peak'
require 'splicing'
require 'identificator_mapping'
require 'transcript_group'


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

transcript_groups = {}
genes_to_process.each do |hgnc_id, gene|
  transcript_groups[hgnc_id] = gene.transcripts_grouped_by_common_exon_structure_on_utr(REGION_LENGTH, all_cages)
end


mtor_targets, translational_genes = read_mtor_mapping('mTOR_mapping.txt')
genes_to_process.each do |hgnc_id, gene|
  transcript_groups[hgnc_id].each do |transcript_group|
    sample_transcript = transcript_group.transcripts.first
    if sample_transcript.strand == '+'
      kozak_region = GenomeRegion.new(sample_transcript.chromosome,
                              sample_transcript.strand,
                              sample_transcript.coding_region.pos_start - 10,
                              sample_transcript.coding_region.pos_start + 10)
      sequence = kozak_region.load_sequence('./genome/hg19/')
    else
      kozak_region = GenomeRegion.new(sample_transcript.chromosome,
                              sample_transcript.strand,
                              sample_transcript.coding_region.pos_end - 10,
                              sample_transcript.coding_region.pos_end + 10)
      sequence = complement(kozak_region.load_sequence('./genome/hg19/').reverse)
    end
    puts "HGNC:#{hgnc_id}\t#{mtor_targets[hgnc_id]}\t#{translational_genes[hgnc_id]}\t#{sequence.each_char.to_a.join("\t")}"
  end
end
