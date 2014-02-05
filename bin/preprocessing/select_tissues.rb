# peak_descriptions_filename = 'robust_phase1_pls_2.tpm.desc121113.osc.txt'
# tissue = 'prostate%20cancer%20cell%20line%3aPC-3'
peak_descriptions_filename, tissue = ARGV.first(2)

raise ArgumentError, 'ruby select_tissues.rb <peak_descriptions file> <tissue name pattern>'  unless peak_descriptions_filename && tissue

pattern = Regexp.new(tissue)

File.open(peak_descriptions_filename) do |f|
  column_is_tissue = false
  column = 0
  columns = []

  f.each_line do |line|
    if line.start_with?('##ParemeterValue') # Yes, it has a typo!
      column_is_tissue = true # latter lines contain tissue names
      next
    end

    if line.start_with?('##ColumnVariables')
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
