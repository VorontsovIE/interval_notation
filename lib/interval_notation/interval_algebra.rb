# EmptySemiInterval -- empty region
# SemiInterval -- single contigious semi-interval
# SemiIntervalSet -- set of several(more than one) non-intersecting contigious semi-intervals. Adjacent regions're glued together

require_relative 'interval_algebra/semi_interval'
require_relative 'interval_algebra/empty_semi_interval'
require_relative 'interval_algebra/semi_interval_set'

module IntervalAlgebra
  # Rethink about exception classes
  # and about extraction of operations into external module
  # Also think about perfomance
  ImpossibleComparison = Class.new(StandardError)
  UnsupportedType = Class.new(TypeError)
  InternalError = Class.new(StandardError)
end
