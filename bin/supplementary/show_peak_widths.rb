rate = 0.2
result = File.readlines('../../weighted_5-utr.txt').map(&:strip).each_slice(3).map.with_object([]) do |(infos, cages_line, sequence), result|
  name = infos[1..-1].split("\t")[1]
  expression = infos.split.last.to_f
  next if expression < 1.0
  cages = cages_line[1..-1].split("\t").map(&:to_i)
  maxcage, pos = cages.each_with_index.max_by{|val,ind| val}
  right_side = (1..Float::INFINITY).lazy.map{|i| pos + i}.take_while{|pos| (0...cages.length).include?(pos)}.take_while{|pos| cages[pos] >= rate*maxcage }.to_a
  left_side = (1..Float::INFINITY).lazy.map{|i| pos - i}.take_while{|pos| (0...cages.length).include?(pos)}.take_while{|pos| cages[pos] >= rate*maxcage }.to_a
  peak_width = 1 + right_side.size + left_side.size
  #result << [name, peak_width]
  if peak_width > 5
    #puts infos
    #puts cages_line
    #puts sequence
    puts name
  end
end

#p Hash[result].sort_by{|k,v| v}
