$:.unshift File.join(File.dirname(File.expand_path(__FILE__)), 'lib')
require 'cage'

cage_files = ARGV
cage_files.each do |filename|
  raise ArgumentError, "File #{filename} doesn't exist"  unless File.exist?(filename)
end

pack_of_cages = cage_files.inject({}) {|result, filename| sum_cages(result, read_cages(filename)) }
cages = mul_cages(pack_of_cages, 1.0 / cage_files.size)
print_cages(cages, $stdout)
