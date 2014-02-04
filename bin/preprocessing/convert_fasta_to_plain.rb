dirname = ARGV.shift

Dir.glob(File.join(dirname, '*.fa')).sort.each do |filename|
  basename = File.basename(filename, File.extname(filename))
  dirname = File.dirname(filename)
  filename_plain = File.join(dirname, "#{basename}.plain")
  $stderr.print "#{filename} --> #{filename_plain} started"
  File.open(filename_plain, 'w') do |fw|
    File.open(filename) do |f|
      f.each_line do |line|
        next  if line.start_with?('>')
        fw.print line.strip
      end
    end
  end
  $stderr.print " --> complete\n"
end
