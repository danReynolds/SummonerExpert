module CollectionHelper
  SIMILARITY_THRESHOLD = 0.7

  def match_collection(collection_entry, collection)
    matcher = Matcher::Matcher.new(collection_entry)
    match = matcher.find_match(collection, SIMILARITY_THRESHOLD)
    match.try(:result) || collection_entry
  end
end
