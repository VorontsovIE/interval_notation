Dir.glob('for_article/source_data/hg18/*.fa') do |filename|
  File.open(filename + 'sta', 'w') do |fw|
    File.open(filename) do |f|
      f.each_line do |line|
        next  if line.start_with?('>')
        fw.print line.strip
      end
    end
  end
end