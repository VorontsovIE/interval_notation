$:.unshift File.join(File.dirname(File.expand_path(__FILE__)),'lib')
require 'identificator_mapping'

# hgnc_ids is a hash {hgnc_id => true-value} for all targets which should be extracted
# if hgnc_ids is :all, FASTA for all genes will be extracted
def extract_fasta(input_file, output_file, hgnc_ids = :all)
  File.open(output_file, 'w') do |fw|
    File.open(input_file) do |f|
      line_iterator = f.each_line
      loop do
        transcript_infos = line_iterator.next
        sequence = line_iterator.next
        cages = line_iterator.next

        hgnc_id = transcript_infos[1..-1].split("\t").first.split(':').last
        if hgnc_ids == :all || hgnc_ids.has_key?(hgnc_id)
          fw.print(transcript_infos)
          fw.print(sequence)
        end
      end
    end
  end
end

mtor_targets, translational_genes = read_mtor_mapping('mTOR_mapping.txt')
extract_fasta('transcripts_after_splicing.out', '5-utr.fasta', mtor_targets)