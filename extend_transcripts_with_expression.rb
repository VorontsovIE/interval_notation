require_relative 'lib/identificator_mapping'
require_relative 'lib/gene'

expression_by_enst = Hash[ File.readlines('source_data_2/transcripts_expression.txt').map(&:strip).map(&:split) ]

genes = Gene.genes_from_file('source_data/protein_coding_genes.txt', 
  {hgnc: 'HGNC ID', approved_symbol: 'Approved Symbol', entrezgene: 'Entrez Gene ID', ensembl: 'Ensembl Gene ID', ensembl_external: 'Ensembl ID(supplied by Ensembl)'}
)
genes_by_ensg = genes.group_by{|gene| gene.ensembl_id}
genes_by_external_ensg = genes.group_by{|gene| gene.ensembl_id_external}
ensgs_by_enst = read_ensgs_by_enst('source_data/mart_export.txt')

enst_in_file = Set.new

File.open('source_data_2/reads_2_vs_hg19_gencodeComprehensive.stats') do |f|
  f.each_line do |line|
    match = line.split.first.match(/ENST\d+/)
    if match
      enst = match[0]
      enst_in_file << enst
      gene_infos = ensgs_by_enst.fetch(enst, []).map do |ensg|
        genes_by_ensg.fetch(ensg) do |ensg_id|
          genes_by_external_ensg.fetch(ensg_id, [])
        end
      end.flatten.map do |gene|
        "#{gene.approved_symbol}(HGNC:#{gene.hgnc_id})"
      end.join(',')

      expression = expression_by_enst[enst] || 'NA'
      puts "#{line.chomp}\t#{expression}\t#{gene_infos}"
    else
      puts line
    end
  end
end

$stderr.puts expression_by_enst.size
$stderr.puts enst_in_file.size
#File.write('transcripts_not_found.txt', expression_by_enst.each_key.reject{|tr| enst_in_file.include?(tr) }.join("\n"))