require 'bioinform'
require 'macroape'

def mark_fasta_file_with_scorings(fasta_file, pwm, threshold)
  poly_n = 'N' * pwm.length
  cage_tails = [0] * pwm.length

  File.open(fasta_file) do |f|
    begin
      loop do
        infos = f.readline.strip[1..-1]
        cages = cage_tails +  f.readline.strip[1..-1].split("\t").map(&:to_i) + cage_tails
        sequence = poly_n + f.readline.strip + poly_n
        scores = (0..(sequence.length - pwm.length)).map{|pos| pwm.score(sequence[pos, pwm.length]) }
        puts infos
        puts scores.count{|s| s >= threshold}
        puts sequence.each_char.to_a.join("\t")
        puts cages.join("\t")
        puts scores.join("\t")
        puts
      end
    rescue
    end
  end
end


fasta_file, pwm_filename,threshold = ARGV.first(3)
raise 'Specify fasta (with cages) file and motif file and threshold'  unless fasta_file && pwm_filename && threshold
threshold = threshold.to_f
pwm = Bioinform::PWM.new(File.read(pwm_filename))
mark_fasta_file_with_scorings(fasta_file, pwm, threshold)