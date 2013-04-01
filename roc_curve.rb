# classifier_values: id => value
# marks: id => true/false
# result: [[tp,fp], ]
def roc_curve(classifier_values, marks)
  tp, fp = 0, 0
  result = []
  ids = classifier_values.sort_by{|k,v| v}.reverse.map{|k,v| k}
  num_positives = marks.count{|k,v| v}
  num_negatives = marks.count{|k,v| !v}
  ids.each do |k|
    if marks[k]
      tp += 1
    else
      fp += 1
    end
    result << [fp.to_f / num_negatives, tp.to_f / num_positives]
  end
  result
end

def area_under_curve(points)
  points.sort_by{|x,y| x}.each_cons(2).map{ |(x1,y1),(x2,y2)|
    (x2-x1)*(y1+y2)/2.0
  }.inject(&:+)
end

def output_curve_data(output_file, points)
  File.open(output_file,'w') do |f|
    points.each do |x,y|
      f.puts "#{x}\t#{y}"
    end
  end
end

data = File.readlines('gene_matching_rates.out').map(&:strip).map(&:split)
classifier_values = Hash[ data.map.with_index{|line,ind| [ind, line[3]]}]
marks = Hash[data.map.with_index{|line,ind| [ind, line[4] =~ /mTOR.*Target/i]}]

roc_points = roc_curve(classifier_values, marks )
puts area_under_curve(roc_points)
#output_curve_data('roc_curve.out', roc_points)