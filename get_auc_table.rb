File.open('auc.txt','w') do |f|
  (0..10).each do |max_distance_from_start|
    (0..10).each do |window_size|
      (0..window_size).each do |min_ct_saturation|
        system("ruby statistics_by_pattern.rb  #{max_distance_from_start} #{window_size} #{min_ct_saturation}")
        auc = `ruby roc_curve.rb`
        f.puts "#{max_distance_from_start}\t#{window_size}\t#{min_ct_saturation}\t#{auc}"
        puts "#{max_distance_from_start}\t#{window_size}\t#{min_ct_saturation}\t#{auc}"
      end
    end
  end
end