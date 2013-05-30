$:.unshift File.join(File.dirname(File.expand_path(__FILE__)), 'lib')
require 'cage'

cage_files = ARGV
cage_files.each do |filename|
  raise ArgumentError, "File #{filename} doesn't exist"  unless File.exist?(filename)
end

#cages = {}
#cage_files.each do |filename|
#  add_cages(cages, read_cages(filename))
#end

all_cages = cage_files.map{|filename| read_cages(filename)}

cages = sum_cages( all_cages )

cages.keys.each do |strand|
  cages[strand].keys.each do |chromosome|
    cages[strand][chromosome].keys.each do |pos|
      cages[strand][chromosome].delete(pos)  if all_cages.count{|cg| cg[strand][chromosome][pos] } <= 1
    end
  end
end

mul_cages_inplace(cages, 1.0 / cage_files.size)

cages.keys.each do |strand|
  cages[strand].keys.each do |chromosome|
    cages[strand][chromosome].each do |pos, val|
      cages[strand][chromosome][pos] = val.floor
    end
  end
end
print_cages(cages, $stdout)
