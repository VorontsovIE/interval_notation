matching_ids = File.readlines('top_motif/meme_tct_results.txt').map{|l| l.strip.split[0] }
matching = []
not_matching = []
File.open('5-utrs_for_meme.txt') do |f|
  f.each_line.map(&:strip).each_slice(2) do |infos, seq|
    if matching_ids.include?(  infos.strip[1..-1].split("\t")[0]  )
      matching << infos << seq
    else
      not_matching << infos << seq
    end
  end
end
File.write('top_motif/results/meme_tct/matching_motifs.txt', matching.join("\n"))
File.write('top_motif/results/meme_tct/not_matching_motifs.txt', not_matching.join("\n"))