require_relative 'intervals/genome_region'
require_relative 'transcript'
require_relative 'peak'
require_relative 'transcript_group'
require_relative 'logger_stub'

class Gene
  attr_reader :hgnc_id, :entrezgene_id, :ensembl_id, :approved_symbol
  attr_accessor :transcripts

  def self.logger=(value)
    @logger = value
  end
  def self.logger
    @logger ||= LoggerStub.new
  end
  def logger
    self.class.logger
  end

  def initialize(hgnc_id, approved_symbol, entrezgene_id, ensembl_id)
    @hgnc_id, @approved_symbol, @entrezgene_id, @ensembl_id = hgnc_id, approved_symbol, entrezgene_id, ensembl_id
    @transcripts = []
  end

  # Gene.new_by_infos('HGNC:10000 RGS4  regulator of G-protein signaling 4  1q23.3  5999', {hgnc: 0, approved_symbol: 1, approved_name: nil, entrez: 4})
  def self.new_by_infos(info_line, column_indices)
    infos = info_line.strip.split("\t")
    hgnc_id, approved_symbol, entrezgene_id, ensembl_id = [:hgnc, :approved_symbol, :entrezgene, :ensembl].map{|column_name|
      idx = column_indices[column_name]
      idx ? infos[idx] : nil
    }
    hgnc_id = (hgnc_id && !hgnc_id.empty?)  ?  hgnc_id.split(':', 2).last.to_i  :  nil
    entrezgene_id = (entrezgene_id && !entrezgene_id.empty?)  ?  entrezgene_id.to_i  :  nil
    ensembl_id = nil  if ensembl_id.empty?
    self.new(hgnc_id, approved_symbol, entrezgene_id, ensembl_id)
  end

  def to_s
    "Gene<HGNC:#{hgnc_id}; #{approved_symbol}; entrezgene:#{entrezgene_id}; ensembl:#{ensembl_id}; #{transcripts.map(&:to_s).join(', ')}>"
  end

  # returns loaded transripts or false if due to some reasons transcripts can't be collected
  def collect_transcripts(entrezgene_transcripts, all_transcripts)
    unless entrezgene_id
      logger.warn "#{self} has no entrezgene_id so we cannot find transcripts"
      return false
    end

    transcripts = []
    transcript_ucsc_ids = entrezgene_transcript_mapping.get_second_by_first_id(entrezgene_id)
    transcript_ucsc_ids.each do |ucsc_id|
      transcript = all_transcripts[ucsc_id]
      if !transcript
        logger.error "#{self}'s transcript with #{ucsc_id} wasn't found. Skip transcript"
      elsif ! transcript.coding?
        logger.warn "#{self}'s #{transcript} has no coding region. Skip transcript"
      else
        transcripts << transcript
      end
    end

    if transcripts.empty?
      logger.error "No one transcript of #{self} was found"
      return false
    end
    self.transcripts = transcripts
  end

  # {[utr, exons_on_utr] => [transcripts]}
  def transcripts_grouped_by_common_exon_structure_on_utr(region_length, all_cages)
    groups_of_transcripts = {}
    group_associated_peaks = {}
    transcripts.each do |transcript|
      utr = transcript.utr_region
      exons_on_utr = transcript.exons_on_utr

      if utr.empty? || exons_on_utr.empty?
        logger.info "#{transcript} with utr #{utr} has no exons on utr #{exons_on_utr}"
        next
      end

      associated_peaks = transcript.peaks_associated.select do |peak|
        peaks_on_exons = peak.intersection(exons_on_utr)
        sum_cages_on_exons = peaks_on_exons.each_region.map{|region| region.load_cages(all_cages).inject(0,:+) }.inject(0, :+)
        if sum_cages_on_exons == 0
          logger.info "#{transcript}\tpeaks_on_exons: #{peaks_on_exons}\t has zero sum of cages on exons"
          false
        else
          true
        end
      end

      if associated_peaks.empty?
        logger.info "#{transcript} has no associated peaks on utr"
        next
      end

      exon_intron_structure_on_utr = [utr, exons_on_utr]  # utr should be here to know boundaries
      groups_of_transcripts[exon_intron_structure_on_utr] ||= []
      groups_of_transcripts[exon_intron_structure_on_utr] << transcript
      group_associated_peaks[exon_intron_structure_on_utr] = associated_peaks
    end

    groups_of_transcripts.map{|exon_intron_structure_on_utr, transcripts|
      utr, exons_on_utr = exon_intron_structure_on_utr
      TranscriptGroup.new(utr, exons_on_utr, transcripts, group_associated_peaks[exon_intron_structure_on_utr])
    }
  end

  # hgnc_id => gene
  # columns is {column_name => column_header} i.e. {hgnc: 'HGNC ID', approved_symbol: 'Approved Symbol', entrezgene: 'Entrez Gene ID', ensembl: 'Ensembl Gene ID'}
  def self.genes_from_file(input_file, columns)
    column_indices = {}
    genes = {}
    File.open(input_file) do |fp|
      fp.each_line do |line|
        if fp.lineno == 1
          column_names = line.strip.split("\t")
          column_indices = columns.inject(Hash.new) do |hsh, (column_name, column_header)|
            idx = column_names.index(column_header)
            hsh.merge(column_name => idx)
          end
        else
          gene = Gene.new_by_infos(line, column_indices)
          genes[gene.hgnc_id] = gene
        end
      end
    end
    genes
  end
end
