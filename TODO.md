* Fix `BasicInterval`'s integer_points for case of infinite boundaries and for case non-integer singular point. How should `IntervalSet#integer_points` work not to generate infinite or even very large sets of points? Possibly it should return an Enumerator and forbid infinite boundaries (or at least minus-infinity). May be it should return points not in direct order but in 0,-1,+1,-2,+2,... order or even without any guaranteed order so that infinite intervals could be processed. It need additional consideration about use-cases and possible drawbacks of each implementation.
* Write benchmarks
* Optimize `#closure`, `#complement`
* Visualization in console and in IRuby (how to scale into 80-symbol or 1200px screen); SVG; TeX formatters
* Remove old git history related to mTOR project
* What about working with simgle intervals (their, length, relations etc)?
* (?) Make it possible to use intervals with non-numeric objects to be possible to use math expressions as interval boundaries
* May be we should check that boundary is an actual number, not a NaN
* Make use of basic intervals (implement #coerce and make oo|co|pt|... return BasicIntervals)