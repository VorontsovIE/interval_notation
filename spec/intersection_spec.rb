require_relative 'spec_helper'

describe IntervalNotation do
  describe IntervalSet do

    describe '#intersection'  do
      {
        [oo(1,3), oo(1,3)] => oo(1,3),
        [oo(1,3), oc(1,3)] => oo(1,3),
        [oo(1,3), co(1,3)] => oo(1,3),
        [oo(1,3), cc(1,3)] => oo(1,3),

        [pt(2), pt(3)] => Empty,
        [pt(3), pt(3)] => pt(3),
        [pt(3)|pt(5), pt(3)|pt(5)] => pt(3)|pt(5),
        [pt(3)|pt(5), pt(3)|pt(7)] => pt(3),

        [oo(1,3)|oo(5,7), oo(1,3)|oo(5,7)] => oo(1,3)|oo(5,7),
        [oo(1,3)|co(5,7), oo(1,3)|oo(5,7)] => oo(1,3)|oo(5,7),
        [oo(1,3)|oo(5,7), oo(1,3)|co(5,7)] => oo(1,3)|oo(5,7),
        [oo(1,3)|co(5,7), oo(1,3)|co(5,7)] => oo(1,3)|co(5,7),

        [oo(1,3)|oo(3,5), oo(1,3)] => oo(1,3),
        [oo(1,3)|oo(3,5), oo(1,3)|oo(7,9)] => oo(1,3),
        [oo(1,3)|oo(3,5), oo(3,5)] => oo(3,5),
        [oo(1,3)|oo(3,5), oo(1,3)|oo(3,5)] => oo(1,3)|oo(3,5),

        [oo(1,3), oo(4,5)] => Empty,
        [oo(1,3), oo(3,5)] => Empty,
        [oo(1,3), co(3,5)] => Empty,
        [oc(1,3), oo(3,5)] => Empty,
        [oc(1,3), co(3,5)] => pt(3),

        [oo(1,3), oo(0,5)] => oo(1,3),
        [oc(1,3), oo(0,5)] => oc(1,3),
        [co(1,3), oo(0,5)] => co(1,3),
        [cc(1,3), oo(0,5)] => cc(1,3),

        [oo(1,3), oo(1,5)] => oo(1,3),
        [co(1,3), oo(1,5)] => oo(1,3),
        [oc(1,3), oo(1,5)] => oc(1,3),
        [cc(1,3), oo(1,5)] => oc(1,3),
        [co(3,5), oo(1,5)] => co(3,5),

        [oo(1,3), oo(2,5)] => oo(2,3),
        [oc(1,3), oo(2,5)] => oc(2,3),
        [oo(1,3), co(2,5)] => co(2,3),
        [oc(1,3), co(2,5)] => cc(2,3),

        [oo(1,3), pt(2)] => pt(2),
        [oo(1,3), pt(3)] => Empty,
        [oc(1,3), pt(3)] => pt(3),
        [oo(1,3), pt(4)] => Empty,
        [oc(1,3), pt(4)] => Empty,

        [oo(1,3)|oo(3,5), oo(2,3)|oo(3,7)] => oo(2,3)|oo(3,5),
        [oo(1,3)|oo(3,5), oo(2,7)] => oo(2,3)|oo(3,5),

        [oo(2,6), oo(1,3)|co(5,7)] => oo(2,3)|co(5,6),
        [oo(1,6), oo(1,3)|co(5,7)] => oo(1,3)|co(5,6),
        [oo(0,6), oo(1,3)|co(5,7)] => oo(1,3)|co(5,6),
        [oo(0,6), oo(1,3)|co(5,6)] => oo(1,3)|co(5,6),


      }.each do |intervals, answer|
        it "IntervalNotation::Operations.intersection(#{intervals.map(&:to_s).join(',')} should equal #{answer}" do
          expect( IntervalNotation::Operations.intersection(intervals) ).to eq answer
        end

        it "IntervalNotation::Operations.intersection(#{intervals.map(&:to_s).join(',')} should equal consequent unite: #{intervals.map(&:to_s).join('&')}" do
          expect( IntervalNotation::Operations.intersection(intervals) ).to eq intervals.inject(&:intersection)
        end

        if intervals.size == 2
          interval_1, interval_2 = intervals
          it "#{interval_1} & #{interval_2} should equal #{answer}" do
            expect( interval_1.intersection(interval_2) ).to eq answer
          end
        end
      end

      {
        [oo(1,3), oo(1,3), oo(1,3)] => oo(1,3),
        [oo(1,3), cc(1,3), oo(1,3)] => oo(1,3),
        [oo(1,3), cc(0,5), cc(1,3)] => oo(1,3),
        [cc(1,5), cc(3,7), cc(1,3)|cc(5,7)] => pt(3)|pt(5),
        [oo(1,5), oo(3,7), oo(1,3)|oo(5,7)] => Empty,
        [oo(1,5), oc(1,3), co(3,5)] => pt(3)
      }.each do |intervals, answer|
        it "#{intervals.map(&:to_s).join('&')} should equal #{answer}" do
          expect( IntervalNotation::Operations.intersection(intervals) ).to eq answer
        end
      end
    end

    # Very extensive automatic testing
    describe '#intersect?', too_extensive_testing: true, slow: true do
      examples = []
      examples += [
        [[oo(1,3)|oo(4,6)|oo(8,10),  oo(3,8)], true],
        [[oo(1,3)|oo(4,6)|oo(8,10)|cc(12,14) ,  oo(3,8)], true],
        [[oo(1,3)|cc(4,6)|oo(8,10),  oo(3,8)], true],
        [[oo(1,3)|pt(5)|oo(8,10),  oo(3,8)], true],
        [[oo(1,3)|oo(8,10),  oo(3,8)], false],
        [[cc(1,3)|cc(8,10),  oo(3,8)], false],

        [[oo(1,3)|oo(8,10),  cc(3,8)], false],
        [[co(1,3)|oc(8,10),  cc(3,8)], false],
        [[oc(1,3)|oo(8,10),  cc(3,8)], true],
        [[oo(1,3)|co(8,10),  cc(3,8)], true],
        [[oc(1,3)|co(8,10),  cc(3,8)], true],
        [[cc(1,3)|cc(8,10),  cc(3,8)], true],

        [[oc(1,3)|oo(8,10),  co(3,8)], true],
        [[oc(1,3)|cc(8,10),  co(3,8)], true],
        [[oo(1,3)|oo(8,10),  co(3,8)], false],
        [[oo(1,3)|cc(8,10),  co(3,8)], false],

        [[oo(1,3)|oo(8,10),  oc(3,8)], false],
        [[oo(1,3)|oc(8,10),  oc(3,8)], false],
        [[oo(1,3)|co(8,10),  oc(3,8)], true],
        [[oo(1,3)|cc(8,10),  oc(3,8)], true],

        [[oo(1,3)|oo(8,10)|cc(12,14),  oo(3,8)], false],
        [[oo(1,3)|oo(8,10)|cc(12,14),  cc(3,8)], false],
        [[oc(1,3)|oo(8,10)|cc(12,14),  cc(3,8)], true],
        [[oc(1,3)|oo(8,10)|cc(12,14),  co(3,8)], true],
        [[oo(1,3)|co(8,10)|cc(12,14),  cc(3,8)], true],
        [[oo(1,3)|co(8,10)|cc(12,14),  oc(3,8)], true],
      ]
      examples += interval_for_each_boundary_type(1,3).flat_map{|interval|
        [
          [[interval, pt(2)], true],
          [[interval, pt(4)], false],
        ]
      }
      examples += pairs_of_intervals_for_each_boundary_with_answer(1,3, 1,3, true)
      examples += pairs_of_intervals_for_each_boundary_with_answer(1,3, 1,2, true)
      examples += pairs_of_intervals_for_each_boundary_with_answer(1,3, 2,3, true)
      examples += pairs_of_intervals_for_each_boundary_with_answer(1,3, 1.5,2.5, true)
      examples += pairs_of_intervals_for_each_boundary_with_answer(1,3, 2,4, true)
      examples += pairs_of_intervals_for_each_boundary_with_answer(1,3, 0,2, true)
      examples += pairs_of_intervals_for_each_boundary_with_answer(1,3, 0,4, true)
      examples += pairs_of_intervals_for_each_boundary_with_answer(1,3, 0,4, true)
      examples += pairs_of_intervals_for_each_boundary_with_answer(1,3, 4,5, false)
      examples += pairs_of_intervals_for_each_boundary_with_answer(1,3, -1,0, false)

      examples += [
        [[oo(1,3), oo(3,4)], false],
        [[oo(1,3), oc(3,4)], false],
        [[oo(1,3), co(3,4)], false],
        [[oo(1,3), cc(3,4)], false],
        [[oo(1,3), oo(0,1)], false],
        [[oo(1,3), oc(0,1)], false],
        [[oo(1,3), co(0,1)], false],
        [[oo(1,3), cc(0,1)], false],
        [[oo(1,3), pt(3)], false],
        [[oo(1,3), pt(1)], false],

        [[co(1,3), oo(3,4)], false],
        [[co(1,3), oc(3,4)], false],
        [[co(1,3), co(3,4)], false],
        [[co(1,3), cc(3,4)], false],
        [[co(1,3), oo(0,1)], false],
        [[co(1,3), oc(0,1)], true],
        [[co(1,3), co(0,1)], false],
        [[co(1,3), cc(0,1)], true],
        [[co(1,3), pt(1)], true],
        [[co(1,3), pt(3)], false],

        [[oc(1,3), oo(3,4)], false],
        [[oc(1,3), oc(3,4)], false],
        [[oc(1,3), co(3,4)], true],
        [[oc(1,3), cc(3,4)], true],
        [[oc(1,3), oo(0,1)], false],
        [[oc(1,3), oc(0,1)], false],
        [[oc(1,3), co(0,1)], false],
        [[oc(1,3), cc(0,1)], false],
        [[oc(1,3), pt(1)], false],
        [[oc(1,3), pt(3)], true],

        [[cc(1,3), oo(3,4)], false],
        [[cc(1,3), oc(3,4)], false],
        [[cc(1,3), co(3,4)], true],
        [[cc(1,3), cc(3,4)], true],
        [[cc(1,3), oo(0,1)], false],
        [[cc(1,3), oc(0,1)], true],
        [[cc(1,3), co(0,1)], false],
        [[cc(1,3), cc(0,1)], true],
        [[cc(1,3), pt(1)], true],
        [[cc(1,3), pt(3)], true],


        [[oo(1,3), oo(4,5)], false],
        [[cc(1,3), cc(4,5)], false],
        [[cc(1,3), pt(2)|cc(4,5)], true],
        [[co(1,3), pt(2)|cc(4,5)], true],
        [[cc(1,3), pt(3)|cc(4,5)], true],
        [[co(1,3), pt(3)|cc(4,5)], false],
        [[cc(1,3), cc(4,5)|pt(6)], false],
      ]

      # Enable to add extensive tests for #intersect? testing
      examples = examples.flat_map{|(interval_1,interval_2), ans|
        [
          [[interval_1, interval_2], ans],
          [[interval_1 | pt(100), interval_2], ans],
          [[interval_1, interval_2 | pt(-100)], ans],
          [[interval_1 | pt(100), interval_2 | pt(-100)], ans],
        ] +
        interval_for_each_boundary_type(-150, -100).flat_map {|interval_3| # distant intervals doesn't interfere intersection property
          [
            [[interval_1, interval_2 | interval_3], ans],
            [[interval_1 | interval_3, interval_2], ans]
          ]
        } +
        interval_for_each_boundary_type(100, 150).flat_map {|interval_3|
          [
            [[interval_1, interval_2 | interval_3], ans],
            [[interval_1 | interval_3, interval_2], ans]
          ]
        } +
        interval_for_each_boundary_type(-150, -100).flat_map {|interval_3|
          interval_for_each_boundary_type(100, 150).flat_map {|interval_4|
            [
              [[interval_1, interval_2|interval_3|interval_4], ans],
              [[interval_1|interval_3|interval_4, interval_2], ans],
              [[interval_1|interval_3, interval_2|interval_4], ans],
              [[interval_1|interval_4, interval_2|interval_3], ans],
            ]
          }
        }
      }

      examples += [
        [[lt(10), oo(1,3)], true],
        [[lt(10), oo(11,12)], false],
        [[lt(10), oo(10,11)], false],
        [[le(10), co(10,11)], true],
        [[le(10), le(9)], true],
        [[le(10), le(11)], true],
        [[le(10), ge(11)], false],
        [[le(10), ge(10)], true],
        [[le(10), gt(10)], false],
        [[le(10), gt(11)], false],
      ]
      examples += examples.flat_map{|(interval_1, interval_2), ans|
        [interval_1, interval_2]
      }.uniq.flat_map{|interval|
        [
          [[interval, Empty], false],
          [[interval, R], interval != Empty],
        ]
      }

      examples.each do |(interval_1, interval_2), answer|
        if answer
          it "#{interval_1}.intersect?(#{interval_2}) should be truthy" do
            expect( interval_1.intersect?(interval_2) ).to be_truthy
          end
          it "#{interval_2}.intersect?(#{interval_1}) should be truthy" do
            expect( interval_2.intersect?(interval_1) ).to be_truthy
          end
        else
          it "#{interval_1}.intersect?(#{interval_2}) should be falsy" do
            expect( interval_1.intersect?(interval_2) ).to be_falsy
          end
          it "#{interval_2}.intersect?(#{interval_1}) should be falsy" do
            expect( interval_2.intersect?(interval_1) ).to be_falsy
          end
        end
      end
    end
  end
end
