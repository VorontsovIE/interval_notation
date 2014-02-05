require 'set'

class Mapping
  attr_accessor :identifier_first_type, :identifier_second_type
  attr_reader :first_to_second, :second_to_first

  def initialize(identifier_first_type, identifier_second_type, first_to_second, second_to_first)
    @identifier_first_type, @identifier_second_type = identifier_first_type.to_sym, identifier_second_type.to_sym
    @first_to_second = first_to_second
    @second_to_first = second_to_first
  end

  def self.from_lines(identifier_first_type, identifier_second_type, lines)
    first_to_second = {}
    second_to_first = {}
    lines.map(&:strip).reject(&:empty?).each do |line|
      first_id, second_id = line.split("\t")
      first_to_second[first_id] ||= []
      first_to_second[first_id] << second_id
      second_to_first[second_id] ||= []
      second_to_first[second_id] << first_id
    end
    self.new(identifier_first_type, identifier_second_type, first_to_second, second_to_first)
  end

  def self.from_file(identifier_first_type, identifier_second_type, filename)
    from_lines(identifier_first_type, identifier_second_type, File.readlines(filename))
  end

  def get_second_by_first_id(id, raise_on_missing_id: true)
    if first_to_second.has_key?(id)
      first_to_second[id]
    elsif raise_on_missing_id
      raise "Unknown id #{id} for map #{identifier_first_type} --> #{identifier_second_type}"
    else
      []
    end
  end

  def get_first_by_second_id(id, raise_on_missing_id: true)
    if second_to_first.has_key?(id)
      second_to_first[id]
    elsif raise_on_missing_id
      raise "Unknown id #{id} for map #{identifier_second_type} --> #{identifier_first_type}"
    else
      []
    end
  end

  def get_by(identifier_type, id, raise_on_missing_id: true)
    case identifier_type.to_sym
    when identifier_first_type
      get_second_by_first_id(id, raise_on_missing_id)
    when identifier_second_type
      get_first_by_second_id(id, raise_on_missing_id)
    else
      raise "Unknown identifier type #{identifier_type}; this mapping is #{identifier_first_type} <--> #{identifier_second_type}"
    end
  end

  # Given mappings {'hgnc_2' => ['entrezgene_2', 'entrezgene_2_pseudo'], 'hgnc_4' => ['entrezgene_4']}, {'entrezgene_2' => ['hgnc_2'], 'entrezgene_4' => ['hgnc_4']}
  # combine(['hgnc_1', 'hgnc_2'], ['entrezgene_2', 'entrezgene_3'])
  # returns [['hgnc_1', nil], ['hgnc_2', 'entrezgene_2'], ['hgnc_2', 'entrezgene_2_pseudo'], [nil, 'entrezgene_3']]
  def combine(first_ids, second_ids)
    results = Set.new
    first_ids.each do |first_id|
      complementary_ids = get_second_by_first_id(first_id, raise_on_missing_id: false)
      results << [first_id, nil]  if complementary_ids.empty?
      complementary_ids.each do |second_id|
        results << [first_id, second_id]
      end
    end
    second_ids.each do |second_id|
      complementary_ids = get_first_by_second_id(second_id, raise_on_missing_id: false)
      results << [nil, second_id]  if complementary_ids.empty?
      complementary_ids.each do |first_id|
        results << [first_id, second_id]
      end
    end
    results.to_a
  end

  def all_pairs
    results = Set.new
    first_to_second.each do |first_id, second_ids|
      second_ids.each do |second_id|
        results << [first_id, second_id]
      end
    end
    second_to_first.each do |second_id, first_ids|
      first_ids.each do |first_id|
        results << [first_id, second_id]
      end
    end
    results.to_a
  end

  def unambiguous?
    first_to_second.none?{|k,v| v.size > 1} && second_to_first.none?{|k,v| v.size > 1 }
  end
end
