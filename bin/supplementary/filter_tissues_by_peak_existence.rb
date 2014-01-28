peak = ARGV.first
raise ArgumentError, 'ruby filter_tissue.rb <peak short description pattern>'  unless peak

pattern = Regexp.new(peak)

File.open('robust_set.freeze1') do |f|
  column_is_tissue = false
  column = 0
  tissue_columns = []
  tissues = []
  number_of_relevant_peaks_for_a_tissue = []

  f.each_line do |line|
    if line.start_with?('##Par')
      column_is_tissue = true
      next
    end
    
    if line.start_with?('##Col')
      if column_is_tissue
        name = line.match(/^##[^\[\]]+\[([^\[\]]+)\]/)[1]
        
        tissues << name
        tissue_columns << column
        
      end

      column +=1
      next
    end

    next  unless line.start_with?('chr')
    splitted_line = line.split("\t")
    peak_short_description = splitted_line[1]
    if peak_short_description.match(pattern)
      #puts "Peak: #{peak_short_description}"
      splitted_line.values_at(*tissue_columns).map(&:to_f).each_with_index{|val,ind|
        number_of_relevant_peaks_for_a_tissue[ind] ||= 0
        number_of_relevant_peaks_for_a_tissue[ind] += val
      }
    end
  end
  #p number_of_relevant_peaks_for_a_tissue
  number_of_relevant_peaks_for_a_tissue.each_with_index.sort_by{|v,ind| v}.reverse.each do |v,ind|
    puts tissues[ind] if number_of_relevant_peaks_for_a_tissue[ind]
  end
end
