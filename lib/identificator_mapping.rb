require_relative 'mapping'

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
    hgnc_string = line[hgnc_column_index].sub(/^HGNC:/,'')
    hgnc = hgnc_string.empty? ? nil : hgnc_string.to_i
    entrez_string = line[entrez_column_index]
    entrez = entrez_string.empty? ? nil : entrez_string.to_i
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
      hgnc_id = hgnc_id.split(':').last.to_i
      mtor_targets[hgnc_id] = hgnc_name
      translational_genes[hgnc_id] = hgnc_name  if hsieh_name.end_with?('=')
    end
  end
  return mtor_targets, translational_genes
end
