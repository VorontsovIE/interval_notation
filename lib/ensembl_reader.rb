require_relative 'intervals/genome_region'
require_relative 'identificator_mapping'
require_relative 'transcript'

module EnsemblReader
  # transcripts_from_ensembl_file(input_file, {enst: 'Ensembl Transcript ID', pos_start: 'Exon Chr Start (bp)', pos_end: 'Exon Chr End (bp)', chromosome: 'Chromosome Name', strand: 'Strand', cds_start: 'Genomic coding start', cds_end: 'Genomic coding end' })

  # returns a list of exons in file
  def self.transcripts_from_ensembl_file(input_file, columns)
    column_indices = {}
    exons_by_transcript = Hash.new{|hsh, enst| hsh[enst] = [] }
    coding_region_by_transcript = Hash.new{|hsh, enst| hsh[enst] = [] }
    File.open(input_file) do |fp|
      fp.each_line.each_with_index do |line, lineno|
        if lineno == 0
          column_indices = column_indices(line, columns)
        else
          enst = *extract_columns(line, [:enst], column_indices)
          coding_region_by_transcript[enst] << coding_segment_by_infos(line, column_indices)
          exons_by_transcript[enst] << exon_by_infos(line, column_indices)
        end
      end
    end
    exons_by_transcript.map do |enst, exon_list|
      coding_region = coding_region_by_transcript[enst].inject(&:union).covering_region
      #raise 'Coding region is not contigious'  unless coding_region.contigious?
      exons = exon_list.inject(&:union)
      Transcript.new(enst, coding_region, exons, nil)
    end  
  end

  # genome_region_by_ensembl_coordinates('11', '-1', '1234', '5678') ==> chr11:1233..5678,-
  def self.genome_region_by_ensembl_coordinates(ensembl_chromosome, ensembl_strand, ensembl_pos_start, ensembl_pos_end)
    chromosome = "chr#{ensembl_chromosome}".to_sym # ensembl chromosomes are named just by number

    case ensembl_strand
      when '1' then strand = :+
      when '-1' then strand = :-
      else raise 'Unknown strand'
    end

    # Ensembl coordinates are 1-based, both ends included
    pos_start = ensembl_pos_start.to_i - 1
    pos_end = ensembl_pos_end.to_i
    
    GenomeRegion.new(chromosome, strand, IntervalAlgebra::SemiInterval.new(pos_start, pos_end))
  end

  # returns exon region by line in ensembl transcripts format
  def self.exon_by_infos(info_line, column_indices)
    ensembl_chromosome, ensembl_strand, ensembl_pos_start, ensembl_pos_end = *extract_columns(info_line, [:chromosome, :strand, :pos_start, :pos_end], column_indices)
    genome_region_by_ensembl_coordinates(ensembl_chromosome, ensembl_strand, ensembl_pos_start, ensembl_pos_end)
  end
  
  # returns coding region segment (each exon in ensembl gives its' own part of coding region, full region is a union) by line in ensembl transcripts format
  def self.coding_segment_by_infos(info_line, column_indices)
    ensembl_chromosome, ensembl_strand, ensembl_cds_start, ensembl_cds_end = *extract_columns(info_line, [:chromosome, :strand, :cds_start, :cds_end], column_indices)
    genome_region_by_ensembl_coordinates(ensembl_chromosome, ensembl_strand, ensembl_cds_start, ensembl_cds_end)
  end
end
