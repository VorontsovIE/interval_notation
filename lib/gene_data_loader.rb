require_relative 'intervals/genome_region'
require_relative 'transcript'
require_relative 'gene'
require_relative 'peak'
require_relative 'splicing'
require_relative 'cage'
require_relative 'identificator_mapping'
require_relative 'transcript_group'
require_relative 'logger_stub'
require_relative 'ensembl_reader'

class GeneDataLoader
  def ensembl_exons_column_names 
    {enst: 'Ensembl Transcript ID', chromosome: 'Chromosome Name', strand: 'Strand',
    pos_start: 'Exon Chr Start (bp)', pos_end: 'Exon Chr End (bp)',
    cds_start: 'Genomic coding start', cds_end: 'Genomic coding end' }
  end

  attr_reader :all_cages, :all_peaks, :all_transcripts
  attr_reader :genes_to_process, :transcript_groups, :number_of_genes_for_a_peak
  attr_accessor :transcript_ensts_to_load

  attr_writer :logger
  def logger; @logger ||= LoggerStub.new;  end

  # region_length - length of region upstream to txStart which is considered to have peaks corresponding to transcript
  attr_reader :cages_file, :peaks_for_tissue_file, :transcript_infos_file, :region_length, :genome_folder
  def initialize(cages_file, peaks_for_tissue_file, transcript_infos_file, region_length, genome_folder)
    @cages_file, @peaks_for_tissue_file, @transcript_infos_file, @region_length, @genome_folder = cages_file, peaks_for_tissue_file, transcript_infos_file, region_length, genome_folder
  end

  def peaks_by_chromosome
    @peaks_by_chromosome ||= @all_peaks.group_by(&:chromosome)
  end

  def setup!
    @all_peaks = Peak.peaks_from_file(peaks_for_tissue_file).reject{|peak| peak.tpm == 0}
    transcripts = EnsemblReader.transcripts_from_ensembl_file(transcript_infos_file, ensembl_exons_column_names, transcript_ensts_to_load)
    
    transcripts.select{|transcript| ! transcript.coding? }.each{|transcript| $stderr.puts("#{transcript} is not coding") }
    $stderr.puts("\n")
    
    transcripts = transcripts.select(&:coding?)
    
    # transcripts.select{|transcript| transcript.utr_5.empty?}.each{|transcript| $stderr.puts "#{transcript} has empty UTR (before transcript augmentation)"}
    # $stderr.puts("\n")
    # transcripts.reject{|transcript| transcript.utr_5.empty?}.select{|transcript| transcript.exons_on_utr.empty?}.each{|transcript| $stderr.puts "#{transcript} has UTR but no exons on UTR (before transcript augmentation)"}
    # $stderr.puts("\n")
    
    transcripts = transcripts.map do |transcript|
      augment_transcript(transcript, peaks_by_chromosome[transcript.chromosome]).tap do |augmented_transcript|
        $stderr.puts "#{transcript} had no related peaks so was removed" if augmented_transcript.nil?
      end
    end.compact

    transcripts.select{|transcript| transcript.utr_5.empty?}.each{|transcript| $stderr.puts "#{transcript} has empty UTR (after transcript augmentation)"}
    $stderr.puts("\n")
    transcripts.reject{|transcript| transcript.utr_5.empty?}.select{|transcript| transcript.exons_on_utr.empty?}.each{|transcript| $stderr.puts "#{transcript} has UTR but no exons on UTR (after transcript augmentation)"}
    $stderr.puts("\n")
    
    @all_transcripts = transcripts.reject{|transcript| transcript.exons_on_utr.empty? }

    @all_cages = read_cages(cages_file)

    # Glue all gene's transcripts with the same UTR into the same TranscriptGroup
    #
    # We do so not to renormalize expression and other quantities between transcripts in a group,
    # because have not enough information about concrete transcripts in a group.
    @transcript_groups = TranscriptGroup.groups_with_common_utr(@all_transcripts, @all_cages)

    # Each peak can affect different transcripts so we distribute its expression
    # equally between all transcript groups whose expression can be affected by this peak
    @transcript_groups.each do |transcript_group|
      transcript_group.summary_expression = calculate_summary_expressions_for_transcript_group(transcript_group)
    end
  end

  def peaks_by_enst
    @peaks_by_enst ||= begin
      result = Hash.new{|hsh, enst| hsh[enst] = []}
      @all_peaks.each{|peak| peak.enst_ids.each{|enst_id| result[enst_id] << peak } }
      result
    end
  end

  def transcript_groups_by_enst
    @transcript_groups_by_enst ||= begin
      result = Hash.new {|hsh, enst| hsh[enst] = [] }
      @transcript_groups.each do |transcript_group|
        transcript_group.transcripts.each do |transcript|
          result[transcript.name] << transcript_group
        end
      end   
      result   
    end
  end

  def number_of_transcript_groups_for_a_peak
    @number_of_transcript_groups_for_a_peak ||= begin
      result = Hash.new{|hsh,peak| hsh[peak] = 0}
      transcript_groups.each do |transcript_group|
        transcript_group.associated_peaks.each{|peak| result[peak] += 1 }
      end
      result
    end
  end
#
# Methods to bind genes, peaks and transcripts
#
  # Selects peaks intersecting exons on UTR of a transcript plus
  # annotated (in FANTOM data) peaks, but only intesecting exons and lying on 5'-UTR upstream expansion
  # Then it expands transcript to the most upstream peak and trim at that point and assigns transcript's associated peaks
  # If no related peaks found - returns nil
  def augment_transcript(transcript, peaks)
    transcript_with_upstream = transcript.expanded_upstream(region_length)
    related_peaks = peaks.select{|peak| peak.region.intersect?(transcript_with_upstream.exons_on_utr) }

    upstream_of_coding_region = transcript.expanded_upstream(Float::INFINITY).exons_on_utr
    related_peaks += peaks_by_enst[transcript.name].select{|peak| peak.region.intersect?(upstream_of_coding_region) }

    related_peaks.uniq!

    transcript_expanded = transcript.expand_and_trim_with_peaks(related_peaks)
    transcript_expanded.associate_peaks(related_peaks)  if transcript_expanded
    transcript_expanded
  end


#
# Methods to renormalize expression
#
  
  # Expression of peak starts, intersecting region
  # It can be used to find peak expression just from exons, if region is a markup of transcript's exons
  def peak_expression_on_region(peak, region, all_cages)
    cages_for_full_region = sum_cages(peak.region, all_cages)
    if cages_for_full_region == 0
      return 0  if peak.tpm == 0
      raise 'Expression of peak is non-zero, while no cages found; It\'s impossible to recalculate expression'
    end
    cages_for_restricted_region = sum_cages(peak.region & region, all_cages)
    fraction_of_cages_on_region = cages_for_full_region.to_f / cages_for_restricted_region
    peak.tpm * fraction_of_cages_on_region
  end

  def calculate_summary_expressions_for_transcript_group(transcript_group)
    peaks_expression = transcript_group.associated_peaks.map{|peak|
      expression = peak_expression_on_region(peak, transcript_group.exons_on_utr, all_cages)
      expression / (number_of_transcript_groups_for_a_peak[peak])
    }
    peaks_expression.inject(0, &:+)
  end

#
# Output results
#
  # block is used to process sequence before output
  def output_all_5utr(output_stream, &block)
    (transcript_ensts_to_load || @all_transcripts.map(&:name)).each do |enst|
      transcript_groups_by_enst[enst].each do |transcript_group|
        utr = transcript_group.utr
        exons_on_utr = transcript_group.exons_on_utr
        if exons_on_utr.empty?
          $stderr.puts "#{transcript_group} has no exons on utr"
          next
        end

        # sequence and cages here are unreversed on '-'-strand. One should possibly reverse both arrays and complement sequence
        cages = utr.load_cages(all_cages)
        sequence = utr.load_sequence(genome_folder)

        # all transcripts in the group have the same associated peaks
        associated_peaks = transcript_group.associated_peaks

        summary_expression = transcript_group.summary_expression
        peaks_info = associated_peaks.map{|peak| peak.region.to_s}.join(';')

        #upstream_of_first_exon =  exons_on_utr.most_upstream_region.upstream(Float::INFINITY)
        #exons_on_utr_plus_upstream = exons_on_utr.union( upstream_of_first_exon.intersection(utr) )

        spliced_sequence = splice_sequence(sequence, utr, exons_on_utr)
        spliced_cages = utr.splice(cages, exons_on_utr)

        if block_given?
          block.call(output_stream, enst, transcript_group, peaks_info, summary_expression, spliced_sequence, spliced_cages, utr, exons_on_utr)
        else
          output_stream.puts ">#{enst}\tSummary expression: #{summary_expression}\tTranscript: #{transcript_group}\tPeaks: #{peaks_info}"
          output_stream.puts spliced_sequence
          output_stream.puts spliced_sequence.each_char.to_a.join("\t")
          output_stream.puts spliced_cages.join("\t")
        end

      end
    end
  end

end
