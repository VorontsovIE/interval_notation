require 'interval_notation'

include IntervalNotation
include IntervalNotation::BasicIntervals
include IntervalNotation::Syntax::Short

describe IntervalNotation do
  describe OpenOpenInterval do
    describe '.new' do
      { [1,3] => :ok,
        [1, Float::INFINITY] => :ok,
        [-Float::INFINITY, 1] => :ok,
        [-Float::INFINITY, Float::INFINITY] => :ok,

        [1,1] => :fail,
        [3,1] => :fail,
        [1,-Float::INFINITY] => :fail,
        [Float::INFINITY, 1] => :fail,
        [-Float::INFINITY, -Float::INFINITY] => :fail,
        [Float::INFINITY, Float::INFINITY] => :fail,
        [Float::INFINITY, -Float::INFINITY] => :fail,
      }.each do |(from, to), result|
        if result == :ok
          it "OpenOpenInterval.new(#{from}, #{to}) should not raise" do 
            expect{ OpenOpenInterval.new(from, to) }.not_to raise_error
          end
        elsif result == :fail
          it "OpenOpenInterval.OpenOpenInterval(#{from}, #{to}) should raise" do
            expect{ OpenOpenInterval.new(from, to) }.to raise_error Error
          end
        else
          raise 'Incorrect test'
        end
      end
    end
  end


  describe OpenClosedInterval do
    describe '.new' do
      { [1,3] => :ok,
        [-Float::INFINITY, 1] => :ok,

        [1, Float::INFINITY] => :fail,
        [-Float::INFINITY, Float::INFINITY] => :fail,
        [1,1] => :fail,
        [3,1] => :fail,
        [1,-Float::INFINITY] => :fail,
        [Float::INFINITY, 1] => :fail,
        [-Float::INFINITY, -Float::INFINITY] => :fail,
        [Float::INFINITY, Float::INFINITY] => :fail,
        [Float::INFINITY, -Float::INFINITY] => :fail,
      }.each do |(from, to), result|
        if result == :ok
          it "OpenClosedInterval.new(#{from}, #{to}) should not raise" do 
            expect{ OpenClosedInterval.new(from, to) }.not_to raise_error
          end
        elsif result == :fail
          it "OpenOpenInterval.new(#{from}, #{to}) should raise" do
            expect{ OpenClosedInterval.new(from, to) }.to raise_error Error
          end
        else
          raise 'Incorrect test'
        end
      end
    end
  end


  describe ClosedOpenInterval do
    describe '.new' do
      { [1,3] => :ok,
        [1, Float::INFINITY] => :ok,

        [-Float::INFINITY, 1] => :fail,
        [-Float::INFINITY, Float::INFINITY] => :fail,
        [1,1] => :fail,
        [3,1] => :fail,
        [1,-Float::INFINITY] => :fail,
        [Float::INFINITY, 1] => :fail,
        [-Float::INFINITY, -Float::INFINITY] => :fail,
        [Float::INFINITY, Float::INFINITY] => :fail,
        [Float::INFINITY, -Float::INFINITY] => :fail,
      }.each do |(from, to), result|
        if result == :ok
          it "ClosedOpenInterval.new(#{from}, #{to}) should not raise" do 
            expect{ ClosedOpenInterval.new(from, to) }.not_to raise_error
          end
        elsif result == :fail
          it "OpenOpenInterval.new(#{from}, #{to}) should raise" do
            expect{ ClosedOpenInterval.new(from, to) }.to raise_error Error
          end
        else
          raise 'Incorrect test'
        end
      end
    end
  end


  describe ClosedClosedInterval do
    describe '.new' do
      { [1,3] => :ok,

        [1, Float::INFINITY] => :fail,
        [-Float::INFINITY, 1] => :fail,
        [-Float::INFINITY, Float::INFINITY] => :fail,
        [1,1] => :fail,
        [3,1] => :fail,
        [1,-Float::INFINITY] => :fail,
        [Float::INFINITY, 1] => :fail,
        [-Float::INFINITY, -Float::INFINITY] => :fail,
        [Float::INFINITY, Float::INFINITY] => :fail,
        [Float::INFINITY, -Float::INFINITY] => :fail,
      }.each do |(from, to), result|
        if result == :ok
          it "ClosedClosedInterval.new(#{from}, #{to}) should not raise" do 
            expect{ ClosedClosedInterval.new(from, to) }.not_to raise_error
          end
        elsif result == :fail
          it "OpenOpenInterval.new(#{from}, #{to}) should raise" do
            expect{ ClosedClosedInterval.new(from, to) }.to raise_error Error
          end
        else
          raise 'Incorrect test'
        end
      end
    end
  end

  describe Point do
    it 'should not raise if finite' do
      expect{ Point.new(3) }.not_to raise_error      
    end
    it 'should raise if infinite' do
      expect{ Point.new(-Float::INFINITY) }.to raise_error      
      expect{ Point.new(Float::INFINITY) }.to raise_error      
    end
  end
end
