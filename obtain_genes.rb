# We don't collect peaks that have zero expression

# TODO:
# Some genes hasn't entrez in mapping but has it in fantom table
# For genes that has no mapping we get mapping from fantom


require 'logger'
$logger = Logger.new($stderr)

# [pos_start; pos_end) region on specified chromosome and strand
# It's required that pos_start <= pos_end
class Region
  attr_reader :chromosome, :strand, :pos_start, :pos_end, :region, :sequence
  
  def ==(other_region)
    chromosome == other_region.chromosome && strand == other_region.strand && pos_start == other_region.pos_start && pos_end == other_region.pos_end
  end
  def eql?(other_region)
    self == other_region
  end
  def hash
    annotation.hash
  end
  
  # region represented a semi-interval: [pos_start; pos_end) Positions are 0-based
  def initialize(chromosome, strand, pos_start, pos_end)
    @chromosome, @strand, @pos_start, @pos_end = chromosome, strand, pos_start, pos_end
    @region = pos_start...pos_end
    raise "Negative length for region #{annotation}"  if length < 0
  end
  
  # Region.new_by_annotation('chr1:564462..564463,+')
  def self.new_by_annotation(name)
    chromosome, name = name.split(':')
    name, strand = name.split(',')
    pos_start, pos_end = name.split('..').map(&:to_i)
    self.new(chromosome, strand, pos_start, pos_end)
  end
  def annotation
    "#{@chromosome}:#{@pos_start}..#{@pos_end},#{@strand}"
  end
  def to_s
    annotation
  end
  
  def same_strand?(other_region)
    other_region.chromosome == chromosome && other_region.strand == strand
  end
  # whether pos is inside of region provided that strand and chromosome are the same
  def include_position?(pos)
    @region.include?(pos)
  end
  # whether region is inside of region
  def include?(other_region)
    same_strand?(other_region) && include_position?(other_region.pos_start) && (include_position?(other_region.pos_end) || pos_end == other_region.pos_end)
  end
  def intersect?(other_region)
    #same_strand?(other_region) && (include?(other_region) || other_region.include?(self) || include_position?(other_region.pos_start) || (include_position?(other_region.pos_end) && other_region.pos_end != pos_start))
    same_strand?(other_region) && !(pos_start >= other_region.pos_end || other_region.pos_start >= pos_end)
  end

  def intersection(other_region)
    return nil unless same_strand?(other_region)
    return nil unless intersect?(other_region)
    # self is [], other_region is ()
    
    if pos_start < other_region.pos_start && other_region.include_position?(pos_end) && other_region.pos_start != pos_end
      # [ ( ] )
      Region.new(chromosome, strand, other_region.pos_start, pos_end)
    elsif pos_end > other_region.pos_end && other_region.include_position?(pos_start)
      # ( [ ) ]
      Region.new(chromosome, strand, pos_start, other_region.pos_end)
    elsif other_region.include?(self)
      # ( [ ] )
      self
    elsif include?(other_region)
      # [ ( ) ]
      other_region
    else
      raise 'Logic error! Intersection undefined'
    end
  end

  def length
    pos_end - pos_start
  end
  
  # genome_dir is a folder with files of different chromosomes
  # here we don't take strand into account
  def load_sequence(genome_dir)
    filename = File.join(genome_dir, "#{chromosome}.plain")
    File.open(filename) do |f|
      f.seek(pos_start)
      f.read(length)
    end
  end

end

class Transcript
  attr_reader :name, :chromosome, :strand, :full_gene_region, :coding_region, :exons, :protein_id, :align_id

  def initialize(name, chromosome, strand, full_gene_region, coding_region, exons, protein_id, align_id)
    @name, @chromosome, @strand, @full_gene_region, @coding_region, @exons, @protein_id, @align_id  = name, chromosome, strand, full_gene_region, coding_region, exons, protein_id, align_id
  end

  # Transcript.new_by_infos('uc001aaa.3	chr1	+	11873	14409	11873	11873	3	11873,12612,13220,	12227,12721,14409,		uc001aaa.3')
  # We don't remove version from name not to have a bug with  uc010nxr.1(chr1)  and  uc010nxr.2(chrY)
  # Be careful about real versions of transcripts, use synchronized databases
  def self.new_by_infos(info)
    name, chromosome, strand, tx_start, tx_end, cds_start, cds_end, exon_count, exon_starts, exon_ends, protein_id, align_id = info.split("\t")
    exon_starts = exon_starts.split(',').map(&:strip).reject(&:empty?).map(&:to_i)
    exon_ends = exon_ends.split(',').map(&:strip).reject(&:empty?).map(&:to_i)
    full_gene_region = Region.new(chromosome, strand, tx_start.to_i, tx_end.to_i)
    coding_region = Region.new(chromosome, strand, cds_start.to_i, cds_end.to_i)
    exons = exon_count.to_i.times.map{|index| Region.new(chromosome, strand, exon_starts[index], exon_ends[index]) }
    self.new(name, chromosome, strand, full_gene_region, coding_region, exons, protein_id, align_id)
  end
  
  def to_s
    "Transcript<#{name}; #{chromosome},#{strand}; with coding_region #{coding_region}>"
  end
  
  # region_length is length of region before txStart(start of transcript) where we are looking for peaks
  def peaks_associated(peaks, region_length)
    if strand == '+'
      region_of_interest = Region.new(chromosome, strand, full_gene_region.pos_start - region_length, coding_region.pos_start)
    else
      region_of_interest = Region.new(chromosome, strand, coding_region.pos_end, full_gene_region.pos_end + region_length)
    end
    peaks.select{|peak| region_of_interest.intersect?(peak.region)}
  end
  
  # region_length is length of region before txStart(start of transcript) where we are looking for peaks
  # utr_region is defined by leftmost peak intersecting region [txStart-region_length; coding_region_start) and by start of coding region
  def utr_region(peaks, region_length)
    associated_peaks = peaks_associated(peaks, region_length)
    if associated_peaks.empty?
      $logger.warn "#{self} has no associated peaks"
      return nil
    end
    
    if strand == '+'
      utr_start = associated_peaks.map{|peak| peak.region.pos_start}.min
      utr_end = coding_region.pos_start
    else
      utr_end = associated_peaks.map{|peak| peak.region.pos_end}.max
      utr_start = coding_region.pos_end
    end
    if utr_start > utr_end
      $logger.error "#{gene}'s UTR can't be evaluated: utr_start=#{utr_start} > utr_end=#{utr_end}"
      return nil
    end
    Region.new(chromosome, strand, utr_start, utr_end)
  end
  
  # region --> [regions]
  
  # |   (         )       
  # |      |--| |---| |--|
  # V 
  #        |--| |-|
  def exons_on_region(region)
    exons_inside = []
    exons.each do |exon|
      exons_inside << region.intersection(exon)  if region.intersect?(exon)
    end
    exons_inside
  end
end

class Gene
  attr_reader :hgnc_id, :approved_symbol, :approved_name
  ### old data: attr_reader :locus_group, :ucsc_id
  attr_reader :chromosome_map, :entrezgene_id
  attr_accessor :transcripts, :peaks
  
  def initialize(hgnc_id, approved_symbol, approved_name, chromosome_map, entrezgene_id)
    @hgnc_id, @approved_symbol, @approved_name, @chromosome_map, @entrezgene_id = hgnc_id, approved_symbol, approved_name, chromosome_map, entrezgene_id
    @transcripts = []
    @peaks = []
  end
  
  ### old data: 'HGNC:10000	RGS4	regulator of G-protein signaling 4	protein-coding gene	uc001gcl.4'
  # Gene.new_by_infos('HGNC:10000	RGS4	regulator of G-protein signaling 4	1q23.3	5999')
  def self.new_by_infos(infos)
    hgnc_id, approved_symbol, approved_name, chromosome_map, entrezgene_id = infos.strip.split("\t")
    hgnc_id = hgnc_id.split(':',2).last
    entrezgene_id = nil  if entrezgene_id && entrezgene_id.empty?
    self.new(hgnc_id, approved_symbol, approved_name, chromosome_map, entrezgene_id)
  end
  
  def to_s
    "Gene<HGNC:#{hgnc_id}; #{approved_symbol}; entrezgene:#{entrezgene_id}; #{transcripts.map(&:to_s).join(', ')}; have #{peaks.size} peaks>"
  end
  
  # returns loaded transripts or false if due to some reasons transcripts can't be collected
  def collect_transcripts(entrezgene_transcripts, all_transcripts)
    unless entrezgene_id
      $logger.warn "#{self} has no entrezgene_id so we cannot find transcripts"
      return false
    end
    
    transcripts = []
    transcript_ucsc_ids = entrezgene_transcripts[entrezgene_id] || []
    transcript_ucsc_ids.each do |ucsc_id|
      transcript = all_transcripts[ucsc_id]
      if transcript
        transcripts << transcript
      else
        $logger.error "#{self}'s transcript with #{ucsc_id} wasn't found. Skip transcript (gene may have another transcripts that are ok)" 
      end
    end
    
    if transcripts.empty?
      $logger.error "No one transcript of #{self} was found"
      return false
    end
    self.transcripts = transcripts  
  end

  # returns loaded peaks or false if due to some reasons peaks can't be collected
  def collect_peaks(all_peaks)
    if all_peaks.has_key?(hgnc_id)
      self.peaks = all_peaks[hgnc_id]
    else
      $logger.warn "#{self} has no peaks in this cell line"
      false
    end
  end
  
  # {[utr, exons_on_utr] => [transcripts]}
  def transcripts_grouped_by_common_exon_structure_on_utr(region_length)
    groups_of_transcripts = {}
    transcripts.each do |transcript|
      utr = transcript.utr_region(peaks, region_length)
      next  unless utr
      exon_intron_structure_on_utr = [utr, transcript.exons_on_region(utr)]  # utr should be here to know boundaries
      groups_of_transcripts[exon_intron_structure_on_utr] ||= []
      groups_of_transcripts[exon_intron_structure_on_utr] << transcript
    end
    groups_of_transcripts
  end
end

class Peak
  attr_reader :annotation, :short_description, :description, :association_with_transcript, :entrezgene_id, :hgnc_id, :uniprot_id, :tpm, :region
  def initialize(annotation, short_description, description, association_with_transcript, entrezgene_id, hgnc_id, uniprot_id, tpm)
    @annotation, @short_description, @description, @association_with_transcript, @entrezgene_id, @hgnc_id, @uniprot_id, @tpm = annotation, short_description, description, association_with_transcript, entrezgene_id, hgnc_id, uniprot_id, tpm
    @region = Region.new_by_annotation(annotation)
  end
  
  # Returns an array of peaks (for each hgnc and entrezgene sticking hgnc and entrezgene together accordantly) basically the same but linked to different genes
  ### (line with infos shortened for brevity)
  ### Peak.new_peaks_by_infos('chr10:102289611..102289643,-	p1@NDUFB8,p1@SEC31B	CAGE_peak_1_at_NDUFB8_5end,CAGE_peak_1_at_SEC31B_5end	0bp_to_AF044958,AF077028,AF115968,NM_005004,uc010qpq.1,uc010qpr.1_5end	entrezgene:4714,entrezgene:25956	HGNC:7703,HGNC:23197	uniprot:O95169,uniprot:A8KAL6	62.734510667127')
  def self.new_peaks_by_infos(infos, hgnc_to_entrezgene, entrezgene_to_hgnc)
    annotation, short_description, description, association_with_transcript, entrezgene, hgnc, uniprot_id, tpm = infos.strip.split("\t")
    tpm = tpm.to_f
    hgnc_ids = hgnc.split(',').map{|hgnc_id| hgnc_id.split(':').last}
    entrezgene_ids = entrezgene.split(',').map{|entrezgene_id| entrezgene_id.split(':').last}
    hgnc_entrezgene_combine(hgnc_to_entrezgene, entrezgene_to_hgnc, hgnc_ids, entrezgene_ids).map{|hgnc_id, entrezgene_id|
      self.new(annotation, short_description, description, association_with_transcript, entrezgene_id, hgnc_id, uniprot_id, tpm)
    }
  end
  
  def to_s
    "Peak<#{annotation}; gene HGNC:#{hgnc_id}>"
  end
  
  def chromosome; region.chromosome; end
  def strand; region.strand; end
  def pos_start; region.pos_start; end
  def pos_end; region.pos_end; end
  
  # region_length is length of region before txStart(start of transcript) where we are looking for peaks
  def transcripts_associated(transcripts, region_length)
    if strand == '+'
      region_of_possibly_associated_trascripts = Region.new(chromosome, strand, pos_start, pos_end + region_length)
    else
      region_of_possibly_associated_trascripts = Region.new(chromosome, strand, pos_start - region_length, pos_end)
    end
    transcripts.select{|ucsc_id, transcript| transcript.full_gene_region.intersect?(region_of_possibly_associated_trascripts)}
  end
  
  ### !!! BAD SOLUTION because we change state of peak while the set of associated transcripts is dependent on region length
  # attr_reader :associated_transcripts
  # def associate_transcript(transcript)
    # @associated_transcripts ||= []
    # @associated_transcripts << transcript
  # end
end

class Sequence
  attr_reader :sequence, :markup
end


# {'hgnc_2' => 'entrezgene_2'}, ['hgnc_1', 'hgnc_2'], ['entrezgene_2', 'entrezgene_3'] --> [['hgnc_1', nil], ['hgnc_2', 'entrezgene_2'], [nil, 'entrezgene_3']]
def hgnc_entrezgene_combine(hgnc_to_entrezgene, entrezgene_to_hgnc, hgnc_ids, entrezgene_ids)
  results = []
  hgnc_ids.each{|hgnc_id| results << [hgnc_id, hgnc_to_entrezgene[hgnc_id]] }
  entrezgenes_without_hgnc = entrezgene_ids.reject{|entrezgene_id| entrezgene_to_hgnc.has_key?(entrezgene_id)}
  entrezgenes_without_hgnc.each{|entrezgene_id| results << [nil, entrezgene_id] }
  results
end

# hgnc_id => gene
def read_genes(input_file)
  genes = {}
  File.open(input_file) do |fp|
    fp.each_line do |line|
      next if fp.lineno == 1
      gene = Gene.new_by_infos(line)
      genes[gene.hgnc_id] = gene
    end
  end
  genes
end

# ucsc_id => transcript
def read_transcripts(input_file)
  transcripts = {}
  File.open(input_file) do |fp|
    fp.each_line do |line|
      transcript = Transcript.new_by_infos(line)
      transcripts[transcript.name] = transcript
    end
  end
  transcripts
end

# hgnc_id => [peaks]
def read_peaks(input_file, hgnc_to_entrezgene, entrezgene_to_hgnc)
  peaks = {}
  File.open(input_file) do |fp|
    fp.each_line do |line|
      next unless line.start_with?('chr')  # this criteium can become insufficient when applied to Drosophila (it has differently named chromosomes)
      pack_of_peaks = Peak.new_peaks_by_infos(line, hgnc_to_entrezgene, entrezgene_to_hgnc)
      pack_of_peaks.each do |peak|
        peaks[peak.hgnc_id] ||= []
        peaks[peak.hgnc_id] << peak
      end
    end
  end
  peaks
end

# input file of lines in format: uc021vde.1	10772
# returns entrezgene => [transcripts]
def read_entrezgene_transcripts(input_file)
  transcripts = {}
  File.open('knownToLocusLink.txt') do |f|
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

def read_cages(input_file)
  cages = {'+' => {}, '-' => {}}
  File.open(input_file) do |f|
    f.each_line do |line|
      # chr1	564462	564463	chr1:564462..564463,+	1	+
      # pos_end is always pos_start+1 because each line is reads from the single position
      chromosome, pos_start, pos_end, region_annotation, num_reads, strand = line.strip.split("\t")
      pos_start, pos_end, num_reads = pos_start.to_i, pos_end.to_i, num_reads.to_i
      cages[strand][chromosome] ||= {}
      cages[strand][chromosome][pos_start] = num_reads
    end
  end
  cages
end

# returns array of cages (not reversed on '-' strand)
def collect_cages(all_cages, region)
  strand_of_cages = all_cages[region.strand][region.chromosome]
  cages = Array.new(region.length)
  local_pos = 0
  region.region.each do |pos|
    cages[local_pos] = strand_of_cages.fetch(pos, 0)
    local_pos +=1
  end
  cages
end

def splice_array(array, utr, exons_on_utr)
  spliced_array = []
  if utr.strand == '+'
    leftmost_exon_start = exons_on_utr.map(&:pos_start).min
    local_pos = 0
    utr.region.each do |pos|
      spliced_array << array[local_pos]  if !leftmost_exon_start || (leftmost_exon_start && pos < leftmost_exon_start) || exons_on_utr.any?{|exon| exon.include_position?(pos) }
      local_pos += 1
    end  
  else
    rightmost_exon_end = exons_on_utr.map(&:pos_end).max
    local_pos = 0
    utr.region.each do |pos|
      spliced_array << array[local_pos]  if !rightmost_exon_end || (rightmost_exon_end && pos >= rightmost_exon_end) || exons_on_utr.any?{|exon| exon.include_position?(pos) }
      local_pos += 1
    end
    spliced_array = spliced_array.reverse
  end
  spliced_array
end

def splice_sequence(sequence, utr, exons_on_utr)
  spliced_sequence = splice_array(sequence, utr, exons_on_utr).join
  utr.strand == '+'  ?  spliced_sequence  :  spliced_sequence.tr('acgtACGT', 'tgcaTGCA')
end

all_cages = read_cages('prostate%20cancer%20cell%20line%253aPC-3.CNhs11243.10439-106E7.hg19.ctss.bed')
hgnc_to_entrezgene, entrezgene_to_hgnc = read_hgnc_entrezgene_mappings('HGNC_protein_coding_22032013_entrez.txt')
entrezgene_transcripts = read_entrezgene_transcripts('knownToLocusLink.txt')
all_peaks = read_peaks('robust_set.freeze1.reduced.pc-3', hgnc_to_entrezgene, entrezgene_to_hgnc)
genes = read_genes('HGNC_protein_coding_22032013_entrez.txt')
all_transcripts = read_transcripts('knownGene.txt')

REGION_LENGTH = 100
genes_to_process = {}
transcript_groups = {}
number_of_genes_for_a_peak = {} # number of genes that have peak in their transcript UTRs.
genes.each do |hgnc_id, gene|
  $logger.warn "Skip #{gene}" and next  unless gene.collect_transcripts(entrezgene_transcripts, all_transcripts)
  $logger.warn "Skip #{gene}" and next  unless gene.collect_peaks(all_peaks)
  genes_to_process[hgnc_id] = gene
  transcript_groups[hgnc_id] = gene.transcripts_grouped_by_common_exon_structure_on_utr(REGION_LENGTH)

  peaks_associated_to_gene = transcript_groups[hgnc_id].collect{|(utr, exons_on_utr), transcripts|
    transcripts.first.peaks_associated(gene.peaks, REGION_LENGTH)
  }.flatten.uniq
  
  peaks_associated_to_gene.each do |peak|
    number_of_genes_for_a_peak[peak] ||= 0
    number_of_genes_for_a_peak[peak] += 1
  end
end

genes_to_process.each do |hgnc_id, gene|  
  transcript_groups[hgnc_id].each do |(utr, exons_on_utr), transcripts|
    # sequence and cages here are unreversed on '-'-strand. One should reverse both arrays and complement sequence
    cages = collect_cages(all_cages, utr)
    sequence = utr.load_sequence('genome/hg19/')
    # all transcripts in the group have the same associated peaks
    associated_peaks = transcripts.first.peaks_associated(gene.peaks, REGION_LENGTH)
    

  
    summary_expression = associated_peaks.map{|peak| 
      num_of_transcript_groups_associated_to_peak = transcript_groups[hgnc_id].count { |(_,_),transcripts_2| 
        transcripts_2.first.peaks_associated(gene.peaks, REGION_LENGTH).include?(peak)
      }
      # Divide expression of each peak equally between genes and then for each gene between glued transcripts
      # Each peak can affect different transcripts so we distribute its expression equally
      # between all transcripts of a single gene whose expression can be affected by this peak
      (peak.tpm.to_f / number_of_genes_for_a_peak[peak]) / num_of_transcript_groups_associated_to_peak
    }.inject(&:+)
    
    ##summary_expression = associated_peaks.map{|peak| peak.tpm.to_f / peak.associated_transcripts.size }.inject(&:+)
    
    gene_info = "HGNC:#{gene.hgnc_id}\t#{gene.approved_symbol}\tentrezgene:#{gene.entrezgene_id}"
    exon_structure_on_utr_info = exons_on_utr.map(&:to_s).join(';')
    transcripts_info = transcripts.map{|transcript| transcript.name }.join(';')
    peaks_info = associated_peaks.map{|peak| peak.region.to_s}.join(';')
    
    spliced_sequence = splice_sequence(sequence, utr, exons_on_utr)
    spliced_cages = splice_array(cages, utr, exons_on_utr)
    
    puts ">#{gene_info}\t#{utr}\t#{exon_structure_on_utr_info}\t#{transcripts_info}\t#{peaks_info}\t#{summary_expression}"
    #puts sequence
    #puts cages.join("\t")
    puts spliced_sequence
    puts spliced_cages.join("\t")
  end
  
end
