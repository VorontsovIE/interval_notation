$:.unshift File.dirname(File.expand_path(__FILE__))
require 'region'

def splice_sequence(sequence, utr, exons_on_utr)
  spliced_sequence = utr.splice(sequence, exons_on_utr).join  
  utr.strand == '+'  ?  spliced_sequence  :  complement(spliced_sequence)
end

# complement, not reverse complement
def complement(sequence)
  sequence.tr('acgtACGT', 'tgcaTGCA')
end