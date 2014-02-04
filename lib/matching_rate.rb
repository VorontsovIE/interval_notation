require_relative 'identificator_mapping'
require 'bioinform'

module Bioinform
  class PWM
    def score(word)
      word = word.upcase
      raise ArgumentError, 'word in PWM#score(word) should have the same length as matrix'  unless word.length == length
      #raise ArgumentError, 'word in PWM#score(word) should have only ACGT-letters'  unless word.each_char.all?{|letter| %w{A C G T}.include? letter}
      (0...length).map do |pos|
        letter = word[pos]
        letter == 'N' ? matrix[pos].inject(&:+).to_f / 4 : matrix[pos][IndexByLetter[letter]]
      end.inject(&:+)
    end
  end
end



def percent_of_starts_matching_pattern(sequence, cages, pattern, max_distance_from_start, min_length)
  sum_of_all_cages = cages.inject(0, &:+)
  sum_of_matching_cages = 0
  complex_pattern = /(.{,#{max_distance_from_start}})(#{pattern})/i
  loop do
    match = sequence.match(complex_pattern)
    raise StopIteration  unless match
    pos = match.begin(0)
    sum_of_matching_cages += cages[pos] if match[2].length >= min_length
    sequence = sequence[pos+1 .. -1]
    cages = cages[pos+1 .. -1]
    raise StopIteration  unless sequence
  end
  sum_of_all_cages != 0  ?  sum_of_matching_cages.to_f / sum_of_all_cages  :  nil
end

# cumulative_ct_saturation is an array where each element(index) is number of specific-nucleotides in a region [0, index)
def cumulative_saturation(sequence, nucleotides)
  result = Array.new(sequence.length + 1)
  result[0] = 0
  sequence.each_char.each_with_index do |letter, pos|
    result[pos + 1] = result[pos] + (nucleotides.include?(letter.upcase) ? 1 : 0)
  end
  result
end

def percent_of_starts_by_ct_saturation(sequence, cages, windows_saturations, 
                                      max_distance_from_start, window_size, min_ct_saturation)
  sum_of_all_cages = cages.inject(0, &:+)
  sum_of_matching_cages = 0

  sequence.length.times do |pos|
    window_saturation = windows_saturations[pos, max_distance_from_start + 1].max || 0
    sum_of_matching_cages += (window_saturation >= min_ct_saturation) ? cages[pos] : 0
  end
  (sum_of_all_cages != 0)  ?  sum_of_matching_cages.to_f / sum_of_all_cages  :  nil
end

def windows_saturations(sequence, window_size, cumulative_ct_saturation)
  # It allows not to check if position out of bounds (which is long operation)
  window_size.times do |pos_after_end|
    cumulative_ct_saturation[sequence.length + pos_after_end] = cumulative_ct_saturation[sequence.length]
  end
  sequence.length.times.map{|pos|
    cumulative_ct_saturation[pos + window_size] - cumulative_ct_saturation[pos]
  }
end

def percent_of_starts_matching_motif(len, cages, max_distance_from_start, match_at_position)
  positions = 0...len
  sum_of_all_cages = cages.inject(0, &:+)
  sum_of_matching_cages = 0
  positions.each{|pos|
    sum_of_matching_cages += cages[pos]  if (match_at_position[pos, max_distance_from_start + 1] || []).any?
  }
  (sum_of_all_cages != 0)  ?  sum_of_matching_cages.to_f / sum_of_all_cages  :  nil
end
