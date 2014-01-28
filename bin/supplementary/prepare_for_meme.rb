filename = ARGV.shift
raise 'Specify input file'  unless filename

File.readlines(filename).map(&:strip).each_slice(2).with_index.map do |(inf,seq),ind|
  inf[1,0] = (1+ind).to_s + '_'
  puts inf
  puts seq
end
