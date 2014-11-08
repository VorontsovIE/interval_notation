utrs = ARGF.readlines.map(&:chomp)
result = utrs.each_slice(4).map do |chunk|
  puts chunk[0]
  puts chunk[1]
end
