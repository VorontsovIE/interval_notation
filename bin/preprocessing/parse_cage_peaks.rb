# Collect only peaks having non-zero exprewssion
# Attention: this script is an OLD(!) Object Oriented version of select_tissues script

class CagePeaksParser
  attr_reader :input_file, :sample_name_pattern, :data
  def initialize(input_file, sample_name_pattern)
    @input_file = input_file
    @sample_name_pattern = sample_name_pattern
    @param_read = false
    @data = []
  end

  def header_line?(line)
    line.start_with? '##'
  end
  def column_line?(line)
    line.start_with? '##Col'
  end
  def parameter_line?(line)
    line.start_with? '##Par'
  end
  def sample_line?(line)
    column_line?(line) && @param_read
  end
  def header_row?(line)
    line.start_with? '00Annotation'
  end

  def header_name(line)
    match = /##.*\[(.*)\]=/.match(line)
    return nil unless match
    match[1]
  end

  def parse
    @columns = []
    index = 0
    File.open(input_file) do |fp|
      fp.each_line do |line|
        raise "Unknown line \"#{line}\""  if header_line?(line) && ! column_line?(line) && ! parameter_line?(line)
        if header_line?(line)
          if parameter_line?(line)
            @param_read = true
            next
          end
          if !sample_line?(line)
            @columns << index
          elsif header_name(line).match(@sample_name_pattern)
            @columns << index
          end
          index += 1
        end
        next  if  header_line?(line) || header_row?(line)
        next  unless line.start_with?('chr')

        data_row = line.strip.split("\t").values_at(*@columns)
        @data << data_row  unless data_row.last.to_f == 0
      end
    end
  end

  def parse_writing_to(output_file)
    @columns = []
    index = 0
    File.open(output_file,'w') do |fw|
      File.open(input_file) do |fp|
        fp.each_line do |line|
          raise "Unknown line \"#{line}\""  if header_line?(line) && ! column_line?(line) && ! parameter_line?(line)
          if header_line?(line)
            if parameter_line?(line)
              @param_read = true
              fw.puts line.strip
              next
            end
            if !sample_line?(line)
              @columns << index
              fw.puts line.strip
            elsif header_name(line).match(@sample_name_pattern)
              @columns << index
              fw.puts line.strip
            end
            index += 1
          end
          fw.puts line.strip.split("\t").values_at(*@columns).join("\t")  if header_row?(line)
          next  if  header_line?(line) || header_row?(line)
          next  unless line.start_with?('chr')

          data_row = line.strip.split("\t").values_at(*@columns)
          unless data_row.last.to_f == 0
            @data << data_row
            fw.puts data_row.join("\t")
          end
        end
      end
    end
  end
end



class GenomePeaks
  # data: {strand => {chromosome => [peaks] } }
  attr_reader :data
  def initialize
    @data = {:+ => {}, :- => {}}
  end
  def <<(peak)
    @data[peak.strand][peak.chromosome] ||= []
    @data[peak.strand][peak.chromosome] << peak
  end
  def include?(segment)
    find(segment) ? true : false
  end
  def find(segment)
    data[segment.strand][segment.chromosome] && data[segment.strand][segment.chromosome].find{|peak| peak.include?(segment) }
  end
end

class CagePointsParser
  attr_reader :input_file, :peaks
  def initialize(input_file, peaks)
    @input_file = input_file
    @peaks = peaks
  end
  def parse
    File.open(input_file) do |fp|
      fp.each_line.with_index do |line,index|
        puts "line #{index}" if index % 100000 == 0
        # chr1	564462	564463	chr1:564462..564463,+	1	+
        chromosome, pos_start, pos_end, name, pieces, strand = line.strip.split("\t")
        pos_start, pos_end = pos_start.to_i, pos_end.to_i
        pieces = pieces.to_i
        cage_point = GenomeSegment.new(chromosome, strand, pos_start, pos_end)
        peak = peaks.find(cage_point)
        peak.supplementary_infos[:cage_points] ||= []
        peak.supplementary_infos[:cage_points] << cage_point
      end
    end
  end
end


if File.exist?('robust_set.freeze1.reduced.pc-3')
  peak_parser = CagePeaksParser.new('robust_set.freeze1.reduced.pc-3', /PC-3/)
  peak_parser.parse
else
  peak_parser = CagePeaksParser.new('robust_set.freeze1', /PC-3/)
  peak_parser.parse_writing_to('robust_set.freeze1.reduced.pc-3')
end

puts 'peaks loaded'

peaks = GenomePeaks.new
peak_parser.data.each do |peak_segment_info, *other_infos|
  peak_segment_info
  segment = GenomeSegment.by_name(peak_segment_info)
  segment.supplementary_infos[:peak_infos] = other_infos
  peaks << segment
end

puts 'peaks collected in a structure'

CagePointsParser.new('prostate%20cancer%20cell%20line%253aPC-3.CNhs11243.10439-106E7.hg19.ctss.bed', peaks).parse
