$:.unshift File.join(File.dirname(File.expand_path(__FILE__)), 'lib')
require 'classifier_quality'

data = File.readlines('gene_matching_rates.out').map(&:strip).map(&:split)
classifier_values = Hash[ data.map.with_index{|line,ind| [ind, line[3]]}]
marks = Hash[data.map.with_index{|line,ind| [ind, line[4] =~ /mTOR.*Target/i]}]

roc_points = roc_curve(classifier_values, marks )
puts area_under_curve(roc_points)
#output_curve_data('roc_curve.out', roc_points)