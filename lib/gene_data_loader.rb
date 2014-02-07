require_relative 'intervals/genome_region'
require_relative 'transcript'
require_relative 'gene'
require_relative 'peak'
require_relative 'splicing'
require_relative 'cage'
require_relative 'identificator_mapping'
require_relative 'transcript_group'
require_relative 'logger_stub'

class GeneDataLoader
  attr_reader :all_cages, :entrezgene_transcript_mapping, :all_peaks, :all_transcripts
  attr_reader :genes_to_process, :transcript_groups, :number_of_genes_for_a_peak

  attr_writer :logger
  def logger; @logger ||= LoggerStub.new;  end

  attr_reader :cages_file, :gene_by_hgnc_file, :hgnc_entrezgene_mapping_file, :transcript_by_entrezgene_file, :peaks_for_tissue_file, :transcript_infos_file, :region_length, :genome_folder
  def initialize(cages_file, gene_by_hgnc_file, hgnc_entrezgene_mapping_file, transcript_by_entrezgene_file, peaks_for_tissue_file, transcript_infos_file, region_length, genome_folder)
    @cages_file = cages_file
    @gene_by_hgnc_file = gene_by_hgnc_file
    @hgnc_entrezgene_mapping_file = hgnc_entrezgene_mapping_file
    @transcript_by_entrezgene_file = transcript_by_entrezgene_file
    @peaks_for_tissue_file = peaks_for_tissue_file
    @transcript_infos_file = transcript_infos_file
    # length of region upstream to txStart which is considered to have peaks corresponding to transcript
    @region_length = region_length
    @genome_folder = genome_folder
  end

  def setup!
    @all_cages = read_cages(cages_file)

    hgnc_entrezgene_mapping = read_hgnc_entrezgene_mapping(hgnc_entrezgene_mapping_file)
    # Don't allow dublicates of either hgnc or entrezgene
    raise "HGNC <--> Entrezgene mapping is ambigous"  if hgnc_entrezgene_mapping.ambigous?
    hgnc_entrezgene_mapping.empty_links.each do |hgnc_id, entrezgene_id|
      logger.info "Incomplete pair: (HGNC:#{hgnc_id}; entrezgene #{entrezgene_id})"
    end

    @entrezgene_transcript_mapping = read_entrezgene_transcript_mapping(transcript_by_entrezgene_file)

    # Очень стремный момент! Мы делаем много клонов одного пика
    @all_peaks = Peak.peaks_from_file(peaks_for_tissue_file, hgnc_entrezgene_mapping)

    @all_transcripts = Transcript.transcripts_from_file(transcript_infos_file)

    # bind peaks to transcripts and transcripts to genes; leave only genes having available coding transcripts and peaks
    # TODO: remove genes having no associated peaks (i.e. all peaks are too far)
    genes = Gene.genes_from_file(gene_by_hgnc_file, {hgnc: 'HGNC ID', approved_symbol: 'Approved Symbol', entrezgene: 'Entrez Gene ID', ensembl: 'Ensembl Gene ID'})
    genes.reject!{|gene| peaks_by_hgnc(gene.hgnc_id).empty? }
    genes.reject!{|gene| coding_transcripts_by_entrezgene(gene.entrezgene_id).empty? }
    @genes_to_process = genes.map{|gene| augmented_gene(gene) }

    @transcript_groups = collect_transcript_groups(@genes_to_process)
    @number_of_genes_for_a_peak = calculate_number_of_genes_for_a_peak(@genes_to_process)

    # Each peak can affect different transcripts so we distribute its expression
    # first equally between all genes whose expression can be affected by this peak
    # and then equally between all transcript groups of that gene

    @genes_to_process.each do |gene|
      @transcript_groups[gene.hgnc_id].each do |transcript_group|
        transcript_group.summary_expression = calculate_summary_expressions_for_transcript_group(transcript_group)
      end
    end
  end

#
# Helper methods to unify loading data by id
#
  def coding_transcripts_by_entrezgene(entrezgene_id)
    transcript_ucsc_ids = entrezgene_transcript_mapping.get_second_by_first_id(entrezgene_id, raise_on_missing_id: false)
    transcript_ucsc_ids.map{|ucsc_id| transcript_by_ucsc(ucsc_id) }.compact.select(&:coding?)
  end

  def peaks_by_hgnc(hgnc_id)
    all_peaks[hgnc_id] || []
  end

  def transcript_by_ucsc(ucsc_id)
    all_transcripts[ucsc_id]
  end

#
# Methods to bind genes, peaks and transcripts
#
  # expand transcripts to upstream with some of given peaks, augment transcript infos with associated peaks
  def augmented_transcripts(transcripts, peaks)
    transcripts_expanded = transcripts.map do |transcript|
      transcript.expanded_upstream(region_length).expand_and_trim_with_peaks(peaks)
    end
    transcripts_expanded.each do |transcript|
      transcript.associate_peaks(peaks)
    end
    transcripts_expanded
  end

  # returns the same Gene object augmented with information about its transcripts
  # (each transcript in the meantime expanded and augmented with associated peaks)
  def augmented_gene(gene)
    transcripts = coding_transcripts_by_entrezgene(gene.entrezgene_id)
    peaks = peaks_by_hgnc(gene.hgnc_id)
    gene.transcripts = augmented_transcripts(transcripts, peaks)
    gene
  end

  # Glue all gene's transcripts with the same UTR into the same TranscriptGroup
  #
  # We do so not to renormalize expression and other quantities between transcripts in a group,
  # because have not enough information about concrete transcripts in a group.
  def collect_transcript_groups(genes)
    Hash[ genes.map{|gene| [gene.hgnc_id, gene.transcripts_grouped_by_common_exon_structure_on_utr(all_cages)]} ]
  end

#
# Methods to renormalize expression
#
  def num_of_transcript_groups_associated_to_peak(peak)
    transcript_groups[peak.hgnc_id].count{|transcript_group| transcript_group.associated_peaks.include?(peak) }
  end

  def calculate_summary_expressions_for_transcript_group(transcript_group)
    peaks_expression = transcript_group.associated_peaks.map{|peak|
      peaks_on_exons = peak.intersection(transcript_group.exons_on_utr)
      sum_cages_on_exons = peaks_on_exons.map{|interval| GenomeRegion.new(peak.chromosome, peak.strand, interval).load_cages(all_cages).inject(0,:+) }.inject(0, :+)
      sum_cages_on_peaks = peak.region.load_cages(all_cages).inject(0, :+)
      percent_of_starts_in_intron = sum_cages_on_exons.to_f / sum_cages_on_peaks
      tpm = peak.tpm.to_f * percent_of_starts_in_intron
      tpm / (number_of_genes_for_a_peak[peak] * num_of_transcript_groups_associated_to_peak(peak))
    }
    peaks_expression.inject(&:+)
  end

  # Calculate number of genes that have specified peak in their transcript(transcript group)'s UTRs.
  def calculate_number_of_genes_for_a_peak(genes)
    number_of_genes_for_a_peak = Hash.new{|hsh,peak| hsh[peak] = 0}
    genes.each do |gene|
      peaks_associated_to_gene = @transcript_groups[gene.hgnc_id].map(&:associated_peaks).flatten.uniq
      peaks_associated_to_gene.each{|peak| number_of_genes_for_a_peak[peak] += 1 }
    end
    number_of_genes_for_a_peak
  end

#
# Output results
#
  # block is used to process sequence before output
  def output_all_5utr(genes_to_process, output_stream, &block)
    genes_to_process.each do |gene|
      @transcript_groups[gene.hgnc_id].each do |transcript_group|
        utr = transcript_group.utr
        exons_on_utr = transcript_group.exons_on_utr

        # sequence and cages here are unreversed on '-'-strand. One should possibly reverse both arrays and complement sequence
        cages = utr.load_cages(all_cages)
        sequence = utr.load_sequence(genome_folder)

        # all transcripts in the group have the same associated peaks
        associated_peaks = transcript_group.associated_peaks

        summary_expression = transcript_group.summary_expression
        gene_info = "HGNC:#{gene.hgnc_id}\t#{gene.approved_symbol}\tentrezgene:#{gene.entrezgene_id}"
        peaks_info = associated_peaks.map{|peak| peak.region.to_s}.join(';')

        upstream_of_first_exon =  exons_on_utr.most_upstream_region.upstream(Float::INFINITY)
        exons_on_utr_plus_upstream = exons_on_utr.union( upstream_of_first_exon.intersection(utr) )

        spliced_sequence = splice_sequence(sequence, utr, exons_on_utr_plus_upstream)
        spliced_cages = utr.splice(cages, exons_on_utr_plus_upstream)

        if block_given?
          block.call(output_stream, gene_info,transcript_group, peaks_info, summary_expression, spliced_sequence, spliced_cages)
        else
          output_stream.puts ">#{gene_info}\t#{transcript_group}\t#{peaks_info}\t#{summary_expression}"
          output_stream.puts spliced_sequence
          output_stream.puts spliced_cages.join("\t")
        end

      end
    end
  end

end
