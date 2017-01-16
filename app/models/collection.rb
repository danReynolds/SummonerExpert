class Collection
  SIMILARITY_THRESHOLD = 0.7

  def initialize(attributes = {})
    @name = attributes[:name].strip
    search_key = Hash.new
    search_key[collection_key] = @name

    if data = Rails.cache.read(search_key) || match_collection(@name, self.class::COLLECTION)
      self.class::ACCESSORS.each do |key|
        instance_variable_set("@#{key}", data[key])
      end
    end
  end

  def match_collection(name, collection)
    matcher = Matcher::Matcher.new(name)
    search_key = Hash.new

    if match = matcher.find_match(collection, SIMILARITY_THRESHOLD)
      search_key[collection_key] = match.result
      Rails.cache.read(search_key)
    end
  end

  def collection_key
    self.class.to_s.downcase.pluralize.to_sym
  end

  def error_message
    errors.messages.map do |key, value|
      "#{key} #{value.first}"
    end.en.conjunction(article: false)
  end
end
