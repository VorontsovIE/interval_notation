# IntervalNotation

`interval_notation` allows one to work with 1D-intervals.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'interval_notation'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install interval_notation

## Usage

`IntervalNotation` provides methods to create intervals with open or closed boundaries or singular points, unite and intersect them, check inclusion into an interval and so on.

In order to construct intervals and interval sets, please use factory methods, not class constructors:
```ruby
include IntervalNotation::Syntax::Short
# Predefined interval sets
R # => (-∞,+∞)
Empty # => ∅
# Singular point
pi = pt(Math::PI) # => {3.141592653589793}
# Finite intervals
interval_1 = oo(1,3) # => (1,3)
interval_2 = oc(3,5) # => (3,5]
interval_3 = co(10,15) # => [10,15)
interval_4 = cc(4,11) # => [4,11]
# Aliases for infinite intervals
interval_5 = lt(7) # => (-∞,7)
interval_6 = le(-3) # => (-∞,-3]
interval_7 = gt(-3) # => (-3,+∞)
interval_8 = ge(5.5) # => [5.5,+∞)
# one can also create infinite intervals using basic methods
interval_5_2 = oo(-Float::INFINITY, 7) # => (-∞,7)
interval_6_2 = oc(-Float::INFINITY, -3) # => (-∞,-3]
interval_7_2 = oo(-3, Float::INFINITY) # => (-3,+∞)
interval_8_2 = co(5.5, Float::INFINITY) # => [5.5,+∞)
# Create interval set from string (see IntervalSet.from_string for details)
interval_9 = interval('{0}U[1,5)U(5,infty)') # => {0}U[1,5)U(5,+∞)
```

If you prefer more descriptive method names, use `IntervalNotation::Syntax::Long`. In such case you'll have `open_open`, `open_closed`, `closed_open`, `closed_closed`, `less_than`, `less_than_or_equal_to`, `greater_than`, `greater_than_or_equal_to` and `point` methods. `interval` is a long-form analog for `int` - to create interval set from string

Consider that no one class is supposed to be used directly! For further details see section **Internal structure**.

### Interval operations
Intervals can be combined in many different ways:
```ruby
include IntervalNotation::Syntax::Long
a = open_closed(0,15) # => (0,15]
b = closed_open(10,25) # => [10,25)
c = point(-5) # => {-5}
bc = b | c # => {-5}∪[10,25)

# Union of a pair of intervals:
a | b # => (0,25)
a.union(b) # ditto

# Intersection:
a & b # => [10,15]
a.intersection(b)

# Difference:
a - b # => (0,10)
a.subtract(b)

# Symmetric difference:
a ^ b # => (0,10)∪(15,25)
a.symmetric_difference(b)

# Interval complement
~a # => (-∞,0]∪(15,+∞)
a.complement

# Interval closure
bc.closure # => {-5}∪[10,25]

# Covering interval
bc.covering_interval # => [-5,25)
```

If you want to combine more than two intervals, you can perform several consequent operations:
```ruby
a | b | c # => {-5}∪(0,25)
a & b & c # => ∅
# or may be
[a,b,c].inject(&:|) # => {-5}∪(0,25)
[a,b,c].inject(&:&) # => ∅
```
But there is a much better and faster way to unite or intersect multiple intervals:
```ruby
IntervalNotation::Operations.union([a,b,c]) # => {-5}∪(0,25]
IntervalNotation::Operations.intersection([a,b,c]) # => ∅
```
If you unite thousands or millions of intervals, you definitely should choose the last method! Do not try to inject intervals one by one for the sake of perfomance. Running time can differ dramatically (seconds vs hours for union of hundreds of thousands intervals).

### Interval queries
One can test whether two intervals intersect, cover one another and so on:
```ruby
Empty.empty? # => true
closed_closed(0,5).empty? # => false

Empty.contiguous? # => true
closed_closed(0,5).contiguous? # => true
point(8).contiguous? # => true
(open_open(0,5) | point(8)).contiguous? # => false

closed_closed(0,5).include_position?(3) # => true
open_open(0,5).include_position?(5) # => false
open_open(0,5).include_position?(8) # => false (actually nil which is falsy)
(open_open(0,5)|open_open(7,9)).include_position?(8)# => true

closed_closed(0,5).intersect?(closed_closed(3,10)) # => true
closed_closed(0,5).intersect?(closed_closed(5,10)) # => true
closed_closed(0,5).intersect?(open_closed(5,10)) # => false
closed_closed(0,5).intersect?(closed_closed(7,10)) # => false

closed_closed(0,5).contain?(closed_closed(2,3)) # => true
closed_closed(2,3).contained_by?(closed_closed(0,5)) # => true
```

Full list of querying methods:
```ruby
interval_set.total_length
interval_set.num_connected_components
interval_set.empty?
interval_set.contiguous?
interval_set.include_position?(position)
interval_set.intersect?(interval_set)
interval_set.contain?(interval_set)
interval_set.contained_by?(interval_set)
```

## Internal structure

`IntervalNotation::IntervalSet` is designed in order to keep ordered list of non-overlapping intervals and represent 1-D point set. Each interval in the `IntervalSet` is an instance of one of following classes: `Point`, `OpenOpenInterval`, `OpenClosedInterval`, `ClosedOpenInterval` or `ClosedOpenInterval` representing contiguous 1-D subsets. One can find them in `IntervalNotation::BasicIntervals` module. None of these classes is intended to be directly instantiated, usually intervals are constructed using factory methods and combining operations.

All factory methods listed above create `IntervalSet`s, wrapping an instance of corresponding interval or point class. All interval set operations create new `IntervalSet`s, even if they contain the only basic interval.

`IntervalSet`s are value objects. Once instantiated they cannot be changed, all operations just create new objects. It also means, you can fearlessly use them as key values in hashes.

Combining of intervals is made by sweep line method, so is linear by number of intervals. Many querying operations (such as `#intersect`) rely on combining intervals thus also have linear complexity. Some of these perfomance drawbacks will be fixed in future.
Query `#include_position?` is made by binary search (so has logarithmic complexity).

`IntervalSet` has two constructors: `.new` and `.new_unsafe`. Use them with caution. Default constructor accepts data in a specially prepared format, while unsafe constructor makes no validation at all (and can create inconsistent obect). But `.new_unsafe` still can be useful when you are absolutely sure, provided data is ok, and a few milliseconds for unnecessary validation make sense.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/interval_notation/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
