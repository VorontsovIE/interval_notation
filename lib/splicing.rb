$:.unshift File.dirname(File.expand_path(__FILE__))
require 'region'

# utr is whole region of untranslated region, exons_on utr is a markup on it.
# only those parts of sequence which are in exons will leave in resulting array/sequence
def splice_array(array, utr, exons_on_utr)
  spliced_array = []
  if utr.strand == '+'
    leftmost_exon_start = exons_on_utr.map(&:pos_start).min
    local_pos = 0
    utr.region.each do |pos|
      spliced_array << array[local_pos]  if !leftmost_exon_start || (leftmost_exon_start && pos < leftmost_exon_start) || exons_on_utr.any?{|exon| exon.include_position?(pos) }
      local_pos += 1
    end  
  else
    rightmost_exon_end = exons_on_utr.map(&:pos_end).max
    local_pos = 0
    utr.region.each do |pos|
      spliced_array << array[local_pos]  if !rightmost_exon_end || (rightmost_exon_end && pos >= rightmost_exon_end) || exons_on_utr.any?{|exon| exon.include_position?(pos) }
      local_pos += 1
    end
    spliced_array = spliced_array.reverse
  end
  spliced_array
end

def splice_sequence(sequence, utr, exons_on_utr)
  spliced_sequence = splice_array(sequence, utr, exons_on_utr).join
  utr.strand == '+'  ?  spliced_sequence  :  spliced_sequence.tr('acgtACGT', 'tgcaTGCA')
end