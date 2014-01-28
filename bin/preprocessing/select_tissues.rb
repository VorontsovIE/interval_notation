tissue = ARGV.first
raise ArgumentError, 'ruby filter_tissue.rb <tissue name pattern>'  unless tissue

pattern = Regexp.new(tissue)

File.open('robust_set.freeze1') do |f|
  column_is_tissue = false
  column = 0
  columns = []

  f.each_line do |line|
    if line.start_with?('##Par')
      column_is_tissue = true
      next
    end

    if line.start_with?('##Col')
      if column_is_tissue
        name = line.match(/^##[^\[\]]+\[([^\[\]]+)\]/)[1]
        if pattern.match(name)
          columns << column
          puts line
        end
      else
        columns << column
        puts line
      end

      column +=1
      next
    end

    next  unless line.start_with?('chr')
    puts line.split("\t").values_at(*columns).join("\t")
  end
end
