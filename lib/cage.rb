$:.unshift File.dirname(File.expand_path(__FILE__))
require 'genome_region'

# returns {strand => {chromosome => {position => num_reads} } } structure
def read_cages(input_file)
  cages = {'+' => {}, '-' => {}}
  File.open(input_file) do |f|
    f.each_line do |line|
      # chr1  564462  564463  chr1:564462..564463,+ 1 +
      # pos_end is always pos_start+1 because each line is reads from the single position
      chromosome, pos_start, pos_end, region_annotation, num_reads, strand = line.strip.split("\t")
      pos_start, pos_end, num_reads = pos_start.to_i, pos_end.to_i, num_reads.to_i
      cages[strand][chromosome] ||= {}
      cages[strand][chromosome][pos_start] = num_reads
    end
  end
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

# sum loaded in memory cage-hashes (not normalized)
def sum_cages(*pack_of_cages)
  result = {}
  pack_of_cages.flatten.each do |cages|
    cages.each do |strand_key, strand|
      result[strand_key] ||= {}
      strand.each do |chromosome_key, chromosome|
        result[strand_key][chromosome_key] ||= Hash.new{|h,k| h[k] = 0 }
        chromosome.each do |pos, cage_value|
          result[strand_key][chromosome_key][pos] += cage_value
        end
      end
    end
  end
  result
end

# multiply all cages with the same number (can be used to normalize sum of cages)
def mul_cages(cages, multiplier)
  result = {}
  cages.each do |strand_key, strand|
    result[strand_key] = {}
    strand.each do |chromosome_key, chromosome|
      result[strand_key][chromosome_key] = Hash.new{|h,k| h[k] = 0}
      chromosome.each do |pos, cage_value|
        result[strand_key][chromosome_key][pos] = cage_value * multiplier
      end
    end
  end
  result
end

def add_cages(initial_cages, *pack_of_cages)
  pack_of_cages.flatten.each do |cages|
    cages.each do |strand_key, strand|
      initial_cages[strand_key] ||= {}
      cages[strand_key].each do |chromosome_key, chromosome|
        initial_cages[strand_key][chromosome_key] ||= {}
        cages[strand_key][chromosome_key].each do |pos, cage_value|
          initial_cages[strand_key][chromosome_key][pos] ||= 0
          initial_cages[strand_key][chromosome_key][pos] += cage_value
        end
      end
    end
  end
  initial_cages
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
