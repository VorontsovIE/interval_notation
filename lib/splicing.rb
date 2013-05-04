$:.unshift File.dirname(File.expand_path(__FILE__))
require 'genome_region'

def splice_sequence(sequence, utr, exons_on_utr)
  spliced_sequence = utr.splice(sequence, exons_on_utr).join  
  utr.strand == '+'  ?  spliced_sequence  :  complement(spliced_sequence)
end

# complement, not reverse complement
def complement(sequence)
  sequence.tr('acgtACGT', 'tgcaTGCA')
end


# marks best start (top `rate` part of them) with poly-N so that motif finding ignore them
def mark_best_starts_as_poly_n(sequence, cages, rate)
  new_sequence = sequence.dup
  sum_cages = cages.inject(&:+)
  cages_taken = 0
  cages_sorted = cages.each_with_index.sort_by{|cage, index| cage}.reverse
  while cages_taken + cages_sorted.first.first <= sum_cages * 0.7
    cage, index = cages_sorted.shift
    cages_taken += cage
    new_sequence[index] = 'N'
  end
  new_sequence
end
