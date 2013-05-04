# criterium must treat classifier_value > threshold as positive
#
# classifier_values: id => value
# marks: id => true/false
# result: [[tp,fp], ]
def roc_curve(classifier_values, marks)
  tp, fp = 0, 0
  result = []
  ids = classifier_values.sort_by{|k,v| v}.reverse.map{|k,v| k}
  num_positives = classifier_values.count{|k,v| marks[k]}
  num_negatives = classifier_values.count{|k,v| !marks[k]}
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
