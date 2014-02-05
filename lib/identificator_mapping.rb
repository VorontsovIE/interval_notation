require_relative 'mapping'

# {'hgnc_2' => 'entrezgene_2'}, {'entrezgene_2' => 'hgnc_2'}, ['hgnc_1', 'hgnc_2'], ['entrezgene_2', 'entrezgene_3']
# --> [['hgnc_1', nil], ['hgnc_2', 'entrezgene_2'], [nil, 'entrezgene_3']]
def hgnc_entrezgene_combine(hgnc_to_entrezgene, entrezgene_to_hgnc, hgnc_ids, entrezgene_ids)
  results = []
  hgnc_ids.each{|hgnc_id| results << [hgnc_id, hgnc_to_entrezgene[hgnc_id]] }
  entrezgenes_without_hgnc = entrezgene_ids.reject{|entrezgene_id| entrezgene_to_hgnc.has_key?(entrezgene_id)}
  entrezgenes_without_hgnc.each{|entrezgene_id| results << [nil, entrezgene_id] }
  results
end


# input file of lines in format: uc021vde.1 10772
# returns entrezgene_id => [transcript_ids]
def read_entrezgene_transcript_ids(input_file)
  transcripts = {}
  File.open(input_file) do |f|
    f.each_line do |line|
      # we don't remove version (part of name after dot)
      transcript_id, entrezgene_id = line.strip.split("\t")
      entrezgene_id = entrezgene_id.to_i
      transcripts[entrezgene_id] ||= []
      transcripts[entrezgene_id] << transcript_id
    end
  end
  transcripts
end

# Don't allow dublicates of either hgnc or entrezgene
# returns both mappings hgnc --> entrezgene and vice-versa
def read_hgnc_entrezgene_mappings(input_file)
  hgnc_to_entrezgene = {}
  entrezgene_to_hgnc = {}
  hgnc_column_number = nil
  entrezgene_column_number = nil
  File.open(input_file) do |f|
    f.each_line do |line|
      if f.lineno == 1
        hgnc_column_number = line.strip.split("\t").index('HGNC ID')
        entrezgene_column_number = line.strip.split("\t").index('Entrez Gene ID')
        next
      else
        line_of_data = line.strip.split("\t")
        hgnc_id, entrezgene_id = line_of_data[hgnc_column_number], line_of_data[entrezgene_column_number]
        hgnc_id = hgnc_id.split(':').last.to_i

        if !entrezgene_id || entrezgene_id.empty?
          $logger.info "HGNC:#{hgnc_id} has no entrezgene_id"
          next
        end
        raise "HGNC:#{hgnc_id} occurs more than once"  if hgnc_to_entrezgene.has_key?(hgnc_id)

        entrezgene_id = entrezgene_id.to_i
        hgnc_to_entrezgene[hgnc_id] = entrezgene_id

        raise "entrezgene:#{entrezgene_id} occurs more than once"  if entrezgene_to_hgnc.has_key?(entrezgene_id)
        entrezgene_to_hgnc[entrezgene_id] = hgnc_id
      end
    end
  end
  [hgnc_to_entrezgene, entrezgene_to_hgnc]
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
  mapping = Mapping.from_pairs(:hgnc, :entrezgene, hgnc_entrez_pairs)
  raise "HGNC <--> Entrezgene mapping is ambigous"  if mapping.ambigous?
  if $logger
    mapping.empty_links.each do |hgnc_id, entrezgene_id|
      $logger.info "Incomplete pair: (HGNC:#{hgnc_id}; entrezgene #{entrezgene_id})"
    end
  end
  mapping
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
