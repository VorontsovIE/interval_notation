require_relative 'intervals/genome_region'

def cages_initial_hash
  cages = {'+' => Hash.new{|h, chromosome| h[chromosome] = Hash.new{|h2,pos| h2[pos] = 0 } },
           '-' => Hash.new{|h, chromosome| h[chromosome] = Hash.new{|h2,pos| h2[pos] = 0 } } }
end
# returns {strand => {chromosome => {position => num_reads} } } structure
def read_cages(input_file)
  read_cages_to(input_file, cages = cages_initial_hash)
  cages
end

# chr1	19287	19288	chr1:19287..19288,+	1	+
def print_cages(cages, out)
  cages.each do |strand_key, strand|
    strand.each do |chromosome_key, chromosome|
      chromosome.each do |pos_start, cage_value|
        pos_end = pos_start + 1
        out.puts([chromosome_key, pos_start, pos_end, "#{chromosome_key}:#{pos_start}..#{pos_end},#{strand_key}", cage_value, strand_key].join("\t"))
      end
    end
  end
end

def mul_cages_inplace(cages, multiplier)
  cages.each do |strand_key, strand|
    cages[strand_key].each do |chromosome_key, chromosome|
      cages[strand_key][chromosome_key].each do |pos, cage_value|
        cages[strand_key][chromosome_key][pos] *= multiplier
      end
    end
  end
  cages
end

# adds cages from new file to a hash (summing cages) and calculating number of files affected each position
# input file has lines in format: chr1  564462  564463  chr1:564462..564463,+ 1 +
# pos_end is always pos_start+1 because each line is reads from the single position
def read_cages_to(input_file, cages, cage_count = nil)
  File.open(input_file) do |f|
    if cage_count 
      f.each_line do |line|
        chromosome, pos_start, pos_end, region_annotation, num_reads, strand = line.strip.split("\t")
        pos_start, num_reads = pos_start.to_i, num_reads.to_i
        cages[strand][chromosome][pos_start] += num_reads
        cage_count[strand][chromosome][pos_start] += 1
      end
      return cages, cage_count
    else
      f.each_line do |line|
        chromosome, pos_start, _, _, num_reads, strand = line.strip.split("\t")
        pos_start, num_reads = pos_start.to_i, num_reads.to_i
        cages[strand][chromosome][pos_start] += num_reads
      end
      return cages
    end
  end
end
