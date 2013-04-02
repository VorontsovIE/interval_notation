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
      # we don't remove version
      transcript_id, entrezgene_id = line.strip.split("\t")
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
  File.open(input_file) do |f|
    f.each_line do |line|
      next  if f.lineno == 1
      line_of_data = line.strip.split("\t")
      hgnc_id, entrezgene_id = line_of_data[0], line_of_data[4]
      hgnc_id = hgnc_id.split(':').last
      
      if !entrezgene_id || entrezgene_id.empty?
        $logger.info "HGNC:#{hgnc_id} has no entrezgene_id"
        next
      end
      raise "HGNC:#{hgnc_id} occurs more than once"  if hgnc_to_entrezgene.has_key?(hgnc_id) 
      hgnc_to_entrezgene[hgnc_id] = entrezgene_id
      
      raise "entrezgene:#{entrezgene_id} occurs more than once"  if entrezgene_to_hgnc.has_key?(entrezgene_id) 
      entrezgene_to_hgnc[entrezgene_id] = hgnc_id
    end
  end
  [hgnc_to_entrezgene, entrezgene_to_hgnc]
end

def read_mtor_carting(input_file)
  mtor_targets = {}
  translational_genes = {}
  File.open(input_file) do |f|
    f.each_line do |line|
      next if f.lineno == 1
      hsieh_name, hgnc_name, hgnc_id = line.strip.split("\t")
      hgnc_id = hgnc_id.split(':').last
      mtor_targets[hgnc_id] = hgnc_name
      translational_genes[hgnc_id] = hgnc_name  if hsieh_name.end_with?('=')
    end
  end
  return mtor_targets, translational_genes
end
