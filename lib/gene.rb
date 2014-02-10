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
