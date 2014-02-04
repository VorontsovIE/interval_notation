require_relative 'intervals/genome_region'

def splice_sequence(sequence, utr, exons_on_utr)
  spliced_sequence = utr.splice(sequence, exons_on_utr).join
  utr.strand == '+'  ?  spliced_sequence  :  complement(spliced_sequence)
end

# complement, not reverse complement
def complement(sequence)
  sequence.tr('acgtACGT', 'tgcaTGCA')
end

def mark_single_best_start_as_poly_n(sequence, cages, window_size)
  new_sequence = sequence.dup
  cages_taken = 0
  cage, index = cages.each_with_index.sort_by{|cage, index| cage}.last

  (index-window_size..index+window_size).each do |pos|
    next if pos < 0
    cages_taken += (cages[pos] || 0)
    new_sequence[pos] = 'N'
  end

  new_sequence
end

# marks best start (top `rate` part of them) with poly-N so that motif finding ignore them
def mark_best_starts_as_poly_n(sequence, cages, rate, window_size)
  new_sequence = sequence.dup
  sum_cages = cages.inject(&:+)
  cages_taken = 0
  cages_sorted = cages.each_with_index.sort_by{|cage, index| cage}.reverse
  while cages_taken < sum_cages * rate
    cage, index = cages_sorted.shift
    (index-window_size..index+window_size).each do |pos|
      next if pos < 0 || pos >= cages.size
      next if new_sequence[pos] == 'N'
      cages_taken += cages[pos]
      new_sequence[pos] = 'N'
    end
  end
  new_sequence
end
