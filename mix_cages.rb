$:.unshift File.join(File.dirname(File.expand_path(__FILE__)), 'lib')
require 'cage'

cage_files = ARGV
cage_files.each do |filename|
  raise ArgumentError, "File #{filename} doesn't exist"  unless File.exist?(filename)
end

cages = {}
cage_files.each do |filename|
  add_cages(cages, read_cages(filename))
end
mul_cages_inplace(cages, 1.0 / cage_files.size)
print_cages(cages, $stdout)
