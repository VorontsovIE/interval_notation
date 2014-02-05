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
  attr_reader :all_cages, :entrezgene_transcript_mapping, :all_peaks, :all_transcripts, :genes
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

    @genes = Gene.genes_from_file(gene_by_hgnc_file, {hgnc: 'HGNC ID', approved_symbol: 'Approved Symbol', entrezgene: 'Entrez Gene ID', ensembl: 'Ensembl Gene ID'})
    @all_transcripts = Transcript.transcripts_from_file(transcript_infos_file)

    @genes_to_process = collect_peaks_and_transcripts_for_genes(@genes)
    @transcript_groups = collect_transcript_groups(@genes_to_process)
    @number_of_genes_for_a_peak = calculate_number_of_genes_for_a_peak(@genes_to_process)

    # Each peak can affect different transcripts so we distribute its expression
    # first equally between all genes whose expression can be affected by this peak
    # and then equally between all transcript groups of that gene

    @genes_to_process.each do |hgnc_id, gene|
      @transcript_groups[hgnc_id].each do |transcript_group|
        transcript_group.summary_expression = calculate_summary_expressions_for_transcript_group(transcript_group)
      end
    end
  end

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

  # collect peaks and transcripts for each gene and return hash {hgnc_id => gene} containing only those genes whose data can be collected
  def collect_peaks_and_transcripts_for_genes(group_of_genes)
    genes_to_process = {}
    group_of_genes.each do |hgnc_id, gene|
      if !all_peaks[hgnc_id] || all_peaks[hgnc_id].empty?
        logger.warn "#{gene} has no peaks in this cell line"
        logger.warn "Skip #{gene}"
        next
      end

      unless gene.entrezgene_id
        logger.warn "#{gene} has no entrezgene_id so we cannot find transcripts"
        logger.warn "Skip #{gene}"
        next
      end

      gene.transcripts = collect_transcripts(gene.entrezgene_id)

      if gene.transcripts.empty?
        logger.error "No one transcript of #{gene} was found"
        logger.warn "Skip #{gene}"
        next
      end

      gene.transcripts.each do |transcript|
        transcript.associate_peaks(all_peaks[hgnc_id], region_length)
      end
      genes_to_process[hgnc_id] = gene
    end
    genes_to_process
  end

  # returns transcripts by gene's entrezgene_id
  def collect_transcripts(entrezgene_id)
    transcripts = []
    transcript_ucsc_ids = entrezgene_transcript_mapping.get_second_by_first_id(entrezgene_id)
    transcript_ucsc_ids.each do |ucsc_id|
      transcript = all_transcripts[ucsc_id]
      if !transcript
        logger.error "Gene entrezgene:#{entrezgene_id}'s transcript #{ucsc_id} wasn't found. Skip transcript"
      elsif ! transcript.coding?
        logger.warn "Gene entrezgene:#{entrezgene_id}'s #{transcript} has no coding region. Skip transcript"
      else
        transcripts << transcript
      end
    end

    transcripts
  end

  # We count all gene with the same UTR as the same transcript group and doesn't
  # renormalize expression and other quantities by number of transcripts in a group,
  # because have not enough information about concrete transcripts in a group.
  def collect_transcript_groups(group_of_genes)
    transcript_groups = {}
    group_of_genes.each do |hgnc_id, gene|
      transcript_groups[hgnc_id] = gene.transcripts_grouped_by_common_exon_structure_on_utr(region_length, all_cages)
    end
    transcript_groups
  end

  # Calculate number of genes that have specified peak in their transcript(transcript group)'s UTRs.
  def calculate_number_of_genes_for_a_peak(group_of_genes)
    number_of_genes_for_a_peak = {}
    group_of_genes.each do |hgnc_id, gene|
      peaks_associated_to_gene = @transcript_groups[hgnc_id].map(&:associated_peaks).flatten.uniq

      peaks_associated_to_gene.each do |peak|
        number_of_genes_for_a_peak[peak] ||= 0
        number_of_genes_for_a_peak[peak] += 1
      end
    end
    number_of_genes_for_a_peak
  end


  # block is used to process sequence before output
  def output_all_5utr(genes_to_process, output_stream, &block)
    genes_to_process.each do |hgnc_id, gene|
      @transcript_groups[hgnc_id].each do |transcript_group|
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
