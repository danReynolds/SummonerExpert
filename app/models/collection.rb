include CollectionHelper

class Collection
  def initialize(**args)
    # Fuzzy match the name for the collection
    @name = args[:name].strip
    @name = CollectionHelper::match_collection(
      args[:name].strip,
      Rails.cache.read(collection_key.pluralize).values
    )

    search_key = {}
    search_key[collection_key] = @name

    if @data = Rails.cache.read(search_key)
      self.class::ACCESSORS.each do |key|
        instance_variable_set("@#{key}", @data[key])
      end
    end
  end

  def collection_key
    self.class.collection_key
  end

  def self.collection_key
    self.to_s.downcase
  end

  def error_message
    errors.messages.map do |key, value|
      "#{key} #{value.first}"
    end.en.conjunction(article: false)
  end
end
