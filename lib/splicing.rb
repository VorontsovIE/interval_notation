$:.unshift File.dirname(File.expand_path(__FILE__))
require 'region'

# utr is whole region of untranslated region, exons_on utr is a markup on it.
# only those parts of sequence which are in exons or pstream of leftmost exon will leave in resulting array/sequence
def splice_array(array, utr, exons_on_utr)
  spliced_array = []
  local_pos = 0
  utr.region.each do |pos|
    spliced_array << array[local_pos]  if exons_on_utr.include_position?(pos) || exons_on_utr.position_upstream?(pos)
    local_pos += 1
  end
  spliced_array = spliced_array.reverse  if utr.strand == '-'
  spliced_array
end

def splice_sequence(sequence, utr, exons_on_utr)
  spliced_sequence = splice_array(sequence, utr, exons_on_utr).join
  utr.strand == '+'  ?  spliced_sequence  :  complement(spliced_sequence)
end

# complement, not reverse complement
def complement(sequence)
  sequence.tr('acgtACGT', 'tgcaTGCA')
end