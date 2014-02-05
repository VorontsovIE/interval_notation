require 'set'

class Mapping
  attr_accessor :identifier_first_type, :identifier_second_type
  attr_reader :first_to_second, :second_to_first

  def initialize(identifier_first_type, identifier_second_type, first_to_second, second_to_first)
    @identifier_first_type, @identifier_second_type = identifier_first_type.to_sym, identifier_second_type.to_sym
    @first_to_second = first_to_second
    @second_to_first = second_to_first
  end

  def self.from_pairs(identifier_first_type, identifier_second_type, pairs)
    first_to_second = {}
    second_to_first = {}
    pairs.each do |first_id, second_id|
      first_to_second[first_id] ||= []
      first_to_second[first_id] << second_id
      second_to_first[second_id] ||= []
      second_to_first[second_id] << first_id
    end
    self.new(identifier_first_type, identifier_second_type, first_to_second, second_to_first)
  end

  def self.from_file(identifier_first_type, identifier_second_type, filename)
    pairs = File.readlines(filename).map(&:strip).reject(&:empty?).map{|line| line.split("\t")}
    from_pairs(identifier_first_type, identifier_second_type, pairs)
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
      get_second_by_first_id(id, raise_on_missing_id: raise_on_missing_id)
    when identifier_second_type
      get_first_by_second_id(id, raise_on_missing_id: raise_on_missing_id)
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
    (pairs_of_hash(first_to_second) + reverse_pairs_of_hash(second_to_first)).to_a
  end

  def ambiguous?
    first_to_second.any?{|k,v| v.size > 1} || second_to_first.any?{|k,v| v.size > 1 }
  end

  def ambiguities
    first_to_second_duplicates = first_to_second.select{|k,v| v.size > 1}
    second_to_first_duplicates = second_to_first.select{|k,v| v.size > 1 }
    (pairs_of_hash(first_to_second_duplicates) + reverse_pairs_of_hash(second_to_first_duplicates)).to_a
  end


  # k=>[v1,v2] --> Set([k,v1],[k,v2])
  def pairs_of_hash(mappings)
    result = Set.new
    mappings.each do |first_id, second_ids|
      second_ids.each do |second_id|
        result << [first_id, second_id]
      end
    end
    result
  end

  # v=>[k1,k2] --> Set([k1,v],[k2,v])
  def reverse_pairs_of_hash(mappings)
    result = Set.new
    mappings.each do |first_id, second_ids|
      second_ids.each do |second_id|
        result << [second_id, first_id]
      end
    end
    result
  end
  private :pairs_of_hash, :reverse_pairs_of_hash
end
