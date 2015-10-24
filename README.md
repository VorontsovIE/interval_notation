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

Sometimes you want to create one of `BasicInterval`s which are underlying structures of `IntervalSet`s. In that case you can use similar constructors with `_basic` suffix like `oo_basic(from, to)` and so on.
Some constructors create not necessary contiguous intervals like `interval(String)` do. Such constructors do not have `*_basic` counterpart.

Note that `BasicInterval` classes are not supposed to be used for interval operations directly! For further details see section **Internal structure**.

### Interval operations
Intervals can be combined in many different ways:
```ruby
include IntervalNotation::Syntax::Long
a = open_closed(0,15) # => (0,15]
b = closed_open(10,25) # => [10,25)
c = point(-5) # => {-5}
d = closed_closed(-200, -100) # => [-200,-100]
bc = b | c # => {-5}∪[10,25)
bcd = b | c | d # => [-200,-100]∪{-5}∪[10,25)

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

# Return connected components (contiguous non-adjacent intervals)
# comprising `IntervalSet` (and wrapped in `IntervalSet`s)
bc.connected_components # => [c, b]

# Return connected components (contiguous non-adjacent intervals)
# comprising `IntervalSet` (in `BasicInterval` representation; not wrapped)
bc.intervals # => [point_basic(-5), closed_open_basic(10,25)]

# Find connected component (BasicInterval representation) which covers a point
bc.interval_covering_point(12) # => [10,25)
```

If you want to combine more than two intervals, you can perform several consequent operations:
```ruby
a | b | c # => {-5}∪(0,25)
a & b & c # => ∅
# or may be
[a,b,c].inject(&:|) # => {-5}∪(0,25)
[a,b,c].inject(&:&) # => ∅
```
But there is a much faster way to unite or intersect multiple intervals:
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

### Segmentation
Another essential structure in a library is a `Segmentation`. Segmentation is a partitioning of number line into adjacent non-ovelapping intervals (covering entire R) such that each segment has its own state. Adjacent segments with the same state are glued.
Segmentation can be used to trace lots of interval sets simultaneously. It's made with help of `Tagging` trace-states. `SingleTagging` and `MultiTagging` allow one to mark each interval set with its own tag and to partition number line into regions with certain tag sets.

```ruby
intervals_tagged          = {oo(0,10) => :A, cc(0,8) => :B, oo(5,15) => :C}
intervals_tagged_dup_tags = {oo(0,10) => :A, cc(0,8) => :B, oo(5,15) => :A}

### Usual tagging returns segments with states which are `Set`s of tags:
IntervalNotation::SweepLine.make_tagging(intervals_tagged)
# => Segmentation: [<(-∞;0): {}>, <{0}: {B}>, <(0;5]: {A, B}>, <(5;8]: {A, B, C}>, <(8;10): {A, C}>, <[10;15): {C}>, <[15;+∞): {}>]

IntervalNotation::SweepLine.make_tagging(intervals_tagged_dup_tags)
# => Segmentation: [<(-∞;0): {}>, <{0}: {B}>, <(0;8]: {A, B}>, <(8;15): {A}>, <[15;+∞): {}>] 

### Multitagging returns segments with states which are `Hash`es of tag counts:
IntervalNotation::SweepLine.make_multitagging(intervals_tagged)
# => Segmentation: [<(-∞;0): {}>, <{0}: {:B=>1}>, <(0;5]: {:A=>1, :B=>1}>, <(5;8]: {:A=>1, :B=>1, :C=>1}>, <(8;10): {:A=>1, :C=>1}>, <[10;15): {:C=>1}>, <[15;+∞): {}>]

IntervalNotation::SweepLine.make_multitagging(intervals_tagged_dup_tags)
# => Segmentation: [<(-∞;0): {}>, <{0}: {:B=>1}>, <(0;5]: {:A=>1, :B=>1}>, <(5;8]: {:A=>2, :B=>1}>, <(8;10): {:A=>2}>, <[10;15): {:A=>1}>, <[15;+∞): {}>]
```

One can create different segmentation states using `SweepLine.make_segmentation` with custom trace-state objects. Operations like union and intersection are made this way, using special trace-states which return true when sweep line intersect any/all of intervals. Trace-state is a special object which can recalculate state when interval boundaries were hit. See `SweepLine::TraceState` module for details.

`Segmentation` have some methods to transform states, query segments and so on:

```ruby
include IntervalNotation
include IntervalNotation::Syntax::Short
segmentation = Segmentation.new([
    Segmentation::Segment.new( lt_basic(0), Set.new ),
    Segmentation::Segment.new( pt_basic(0), Set.new([:B]) ),
    Segmentation::Segment.new( oc_basic(0,8), Set.new([:A,:B]) ),
    Segmentation::Segment.new( oo_basic(8,15), Set.new([:A]) ),
    Segmentation::Segment.new( ge_basic(15), Set.new ),
])
# Segmentation: [<(-∞;0): {}>, <{0}: {B}>, <(0;8]: {A, B}>, <(8;15): {A}>, <[15;+∞): {}>]

### `Segmentation#map_state` transforms state of each segment.
### If necessary new segments will be glued
segmentation.map_state{|segment| segment.state.size }
# => Segmentation: [<(-∞;0): 0>, <{0}: 1>, <(0;8]: 2>, <(8;15): 1>, <[15;+∞): 0>]

segmentation.map_state{|segment| segment.state.size > 1 }
# => Segmentation: [<(-∞;0]: false>, <(0;8]: true>, <(8;+∞): false>] 

### `Segmentation#boolean_segmentation` transforms state of each segment into
### boolean value (useful to glue segments which are truthy/falsy but
### have not exactly equal state). Same result can be obtained by `#map_state`.
segmentation.boolean_segmentation{|segment| segment.state.size > 1 }
# => Segmentation: [<(-∞;0]: false>, <(0;8]: true>, <(8;+∞): false>] 


### `IntervalSet` and true/false `Segmentation` can be converted 
### to each other.
### Use `IntervalSet#make_segmentation` and `Segmentation#make_interval_set`.
bool_segmentation = segmentation.boolean_segmentation{|segment|
    segment.state.size > 1
}
bool_segmentation.make_interval_set
# => (0,8]

(oo(1,3) | pt(5)).make_segmentation
# => Segmentation: [<(-∞;1]: false>, <(1;3): true>, <[3;5): false>, <{5}: true>, <(5;+∞): false>]

### `Segmentation#segment_covering_point` returns a `Segment`
### which lies against specified point
segmentation.segment_covering_point(10)
# => <(8;15): {A}>
```

## Internal structure

`IntervalNotation::IntervalSet` is designed in order to keep ordered list of non-overlapping intervals and represent 1-D point set. Each interval in the `IntervalSet` is an instance of one of following classes: `Point`, `OpenOpenInterval`, `OpenClosedInterval`, `ClosedOpenInterval` or `ClosedOpenInterval` representing contiguous 1-D subsets. One can find them in `IntervalNotation::BasicIntervals` module. None of these classes is intended to be directly instantiated, usually intervals are constructed using factory methods and combining operations.

All factory methods listed above create `IntervalSet`s, wrapping an instance of corresponding interval or point class. All interval set operations create new `IntervalSet`s, even if they contain the only basic interval.

`IntervalSet`s and `Segmentation`s (as well as `BasicInterval`s) are value objects. Once instantiated they cannot be changed, all operations just create new objects. It also means, you can fearlessly use them as key values in hashes.

Combining of intervals is made by sweep line method, so is linear by number of intervals. Many querying operations (such as `#intersect`) rely on combining intervals thus also have linear complexity. Some of these perfomance drawbacks will be fixed in future.
Query `#include_position?` is made by binary search (so has logarithmic complexity).

`IntervalSet` has two constructors: `.new` and `.new_unsafe`. Use them with caution. Default constructor accepts data in a specially prepared format, while unsafe constructor makes no validation at all (and can create inconsistent obect). But `.new_unsafe` still can be useful when you are absolutely sure, provided data is ok, and a few milliseconds for unnecessary validation make sense.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/interval_notation/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
