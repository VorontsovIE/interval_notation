# make one cage file from several technical replicas with cages

require_relative '../../lib/cage'
time_start = Time.now

# reject positions which're presented in the only replica
reject_singular_positions = ARGV.delete('--reject-singular-positions')

cage_files = ARGV
cage_files.each do |filename|
  raise ArgumentError, "File #{filename} doesn't exist"  unless File.exist?(filename)
end

cages = cages_initial_hash
cage_count = cages_initial_hash
cage_files.each do |filename|
  $stderr.puts "started reading #{filename} in #{Time.now - time_start}"
  read_cages_to(filename, cages, cage_count)
  $stderr.puts "finished reading #{filename} in #{Time.now - time_start}"
end
$stderr.puts "all cages read in #{Time.now - time_start}"


if reject_singular_positions
  # remove all cages that are in the only replica
  cages.each do |strand_key,strand|
    strand.each do |chromosome_key,chromosome|
      cage_count[strand_key][chromosome_key].each do |pos, cnt|
        chromosome.delete(pos)  if cnt <= 1
      end
    end
  end
  $stderr.puts "removed all cages which are in the only replica in #{Time.now - time_start}"
end

# mean cages
mul_cages_inplace(cages, 1.0 / cage_files.size)
$stderr.puts "cages averaged in #{Time.now - time_start}"

# round cages down and remove all which are zeros
cages.each do |strand_key, strand|
  strand.each do |chromosome_key, chromosome|
    chromosome.each_key do |pos|
      chromosome[pos] = chromosome[pos].floor
    end
    chromosome.each_key do |pos|
      chromosome.delete(pos)  if chromosome[pos] == 0
    end
  end
end
$stderr.puts "cages rounded down, zeros removed in #{Time.now - time_start}"

print_cages(cages, $stdout)
