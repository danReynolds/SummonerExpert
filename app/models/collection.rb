class Collection
  SIMILARITY_THRESHOLD = 0.7

  def match_collection(name, collection)
    collection_key = self.class.to_s.downcase.pluralize.to_sym
    matcher = Matcher::Matcher.new(name)

    search_key = Hash.new
    if match = matcher.find_match(collection, SIMILARITY_THRESHOLD)
      search_key[collection_key] = match.result
      Rails.cache.read(search_key)
    end
  end
end
