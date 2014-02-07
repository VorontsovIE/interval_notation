require_relative 'intervals/genome_region'
require_relative 'transcript'
require_relative 'peak'
require_relative 'transcript_group'
require_relative 'logger_stub'
require_relative 'identificator_mapping'

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
    hgnc_id = hgnc_from_string(hgnc_id)
    entrezgene_id = entrezgene_from_string(entrezgene_id, with_prefix: false)
    ensembl_id = ensembl_from_string(ensembl_id)
    self.new(hgnc_id, approved_symbol, entrezgene_id, ensembl_id)
  end

  def to_s
    "Gene<HGNC:#{hgnc_id}; #{approved_symbol}; entrezgene:#{entrezgene_id}; ensembl:#{ensembl_id}; #{transcripts.map(&:to_s).join(', ')}>"
  end

  # {[utr, exons_on_utr] => [transcripts]}
  def transcripts_grouped_by_common_exon_structure_on_utr(all_cages)
    groups_of_transcripts = {}
    group_associated_peaks = {}
    transcripts.each do |transcript|
      utr = transcript.utr_5
      exons_on_utr = transcript.exons_on_utr

      if utr.empty? || exons_on_utr.empty?
        logger.info "#{transcript} with utr #{utr} has no exons on utr #{exons_on_utr}"
        next
      end

      associated_peaks = transcript.peaks_associated.select do |peak|
        peaks_on_exons = peak & exons_on_utr
        sum_cages_on_exons = sum_cages(peaks_on_exons)
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

  # Given header of the table it returns indices of columns (0-based) titled as specified.
  # Columns should be a hash from column names to according column titles
  # e.g. {hgnc: 'HGNC ID', approved_symbol: 'Approved Symbol', entrezgene: 'Entrez Gene ID', ensembl: 'Ensembl Gene ID'}
  def column_indices(line, columns)
    column_names = line.strip.split("\t")
    columns.inject(Hash.new) do |hsh, (column_name, column_header)|
      idx = column_names.index(column_header)
      hsh.merge(column_name => idx)
    end
  end

  # returns a list of genes in file
  def self.genes_from_file(input_file, columns)
    column_indices = {}
    genes = []
    File.open(input_file) do |fp|
      fp.each_line do |line|
        if fp.lineno == 1
          column_indices = column_indices(line, columns)
        else
          genes << Gene.new_by_infos(line, column_indices)
        end
      end
    end
    genes
  end
end
