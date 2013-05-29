Dir.glob('for_article/source_data/hg18/*.fa') do |filename|
  basename = File.basename(filename, File.extname(filename))
  dirname = File.dirname(filename)
  File.open(File.join(dirname, "#{basename}.plain"), 'w') do |fw|
    File.open(filename) do |f|
      f.each_line do |line|
        next  if line.start_with?('>')
        fw.print line.strip
      end
    end
  end
end