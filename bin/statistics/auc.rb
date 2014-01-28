$:.unshift '../../lib'
require 'classifier_quality'

if $stdin.tty?
  filename = ARGV.shift
  raise 'Specify input file' unless filename
  data = File.readlines(filename)
else
  data = $stdin.readlines
end
roc_points = data.map{|l| l.strip.split.map(&:to_f)}

puts area_under_curve(roc_points)
