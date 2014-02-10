require_relative 'mapping'

def identificator_from_string(str, with_prefix: true)
  if !str || str.empty? || str == 'NA'
    nil
  elsif with_prefix
    str.split(':').last.to_i
  else
    str.to_i
  end
end

# '1234' or 'HGNC:1234'
def hgnc_from_string(str, with_prefix: true)
  identificator_from_string(str, with_prefix: with_prefix)
end
# '1234' or 'entrezgene:1234'
def entrezgene_from_string(str, with_prefix: true)
  identificator_from_string(str, with_prefix: with_prefix)
end
# 'ENSG00000117152' or 'ensembl:ENSG00000117152''
def ensembl_from_string(str, with_prefix: false)
  if !str || str.empty?
    nil
  elsif with_prefix
    str.split(':').last
  else
    str
  end
end

# input file of lines in format: uc021vde.1 10772
# returns entrezgene_id => [transcript_ids] mapping
def read_entrezgene_transcript_mapping(input_file)
  entrez_ucsc_pairs = File.readlines(input_file).map do |line|
    # we don't remove version (part of name after dot)
    transcript_id, entrezgene_id = line.strip.split("\t")
    [transcript_id, entrezgene_id.to_i]
  end
  Mapping.new(:entrezgene, :ucsc, entrez_ucsc_pairs)
end

def read_hgnc_entrezgene_mapping(input_file)
  hgnc_entrez_lines = File.readlines(input_file).map{|l| l.strip.split("\t")}
  column_names = hgnc_entrez_lines.shift
  hgnc_column_index = column_names.index('HGNC ID')
  entrez_column_index = column_names.index('Entrez Gene ID')
  hgnc_entrez_pairs = hgnc_entrez_lines.map do |line|
    hgnc = hgnc_from_string(line[hgnc_column_index])
    entrez = entrezgene_from_string(line[entrez_column_index], with_prefix: false)
    [hgnc, entrez]
  end
  Mapping.from_pairs(:hgnc, :entrezgene, hgnc_entrez_pairs)
end

def read_mtor_mapping(input_file)
  mtor_targets = {}
  translational_genes = {}
  File.open(input_file) do |f|
    f.each_line do |line|
      next if f.lineno == 1
      hsieh_name, hgnc_name, hgnc_id = line.strip.split("\t")
      hgnc_id = hgnc_from_string(hgnc_id)
      mtor_targets[hgnc_id] = hgnc_name
      translational_genes[hgnc_id] = hgnc_name  if hsieh_name.end_with?('=')
    end
  end
  return mtor_targets, translational_genes
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
