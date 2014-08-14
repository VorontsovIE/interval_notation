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
    transcript_id, entrezgene_id = line.chomp.split("\t")
    [transcript_id, entrezgene_id.to_i]
  end
  Mapping.new(:entrezgene, :ucsc, entrez_ucsc_pairs)
end

def read_hgnc_entrezgene_mapping(input_file)
  hgnc_entrez_lines = File.readlines(input_file).map{|l| l.chomp.split("\t")}
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
      hsieh_name, hgnc_name, hgnc_id = line.chomp.split("\t")
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
  column_names = line.chomp.split("\t")
  columns.inject(Hash.new) do |hsh, (column_name, column_header)|
    idx = column_names.index(column_header)
    hsh.merge(column_name => idx)
  end
end

# parse line with data and extracts cell values of +column_names+ columns from cells, according to order defined by +column_indices+
def extract_columns(info_line, column_names, column_indices)
  infos = info_line.chomp.split("\t")
  column_names.map{|column_name|
    idx = column_indices[column_name]
    idx ? infos[idx] : nil
  }
end

# converts list to a hash indexed by id_block (e.g. by hgnc_id or by name)
def collect_hash_by_id(list, &id_block)
  list.each_with_object(Hash.new){|element, hsh| hsh[ id_block.call(element) ] = element }
end

def read_gene_mapping(input_file)
  lines = File.readlines(input_file)
  column_indices = column_indices(lines.first, {hgnc: 'HGNC ID', approved_symbol: 'Approved Symbol', entrezgene: 'Entrez Gene ID', ensembl: 'Ensembl Gene ID'})
  lines.drop(1).map do |line|
    hgnc_id, approved_symbol, entrezgene_id, ensembl_id = *extract_columns(line, [:hgnc, :approved_symbol, :entrezgene, :ensembl], column_indices)
    Gene.new(hgnc_id, approved_symbol, entrezgene_id, ensembl_id)
  end
end

def read_ensgs_by_enst(input_file)
  lines = File.readlines(input_file)
  column_indices = column_indices(lines.first, {ensg: 'Ensembl Gene ID', enst: 'Ensembl Transcript ID'})
  mapping = Hash.new{|hsh, enst| hsh[enst] = [] }
  lines.drop(1).map.with_object(mapping) do |line, result|
    ensg, enst = *extract_columns(line, [:ensg, :enst], column_indices)
    result[enst] << ensg
  end
end
