include CollectionHelper

class Collection
  def initialize(**args)
    # Fuzzy match the name for the collection
    collection_entries = Cache.get_collection(collection_key.pluralize)
    @id = args[:id]

    @name = if args[:name]
      CollectionHelper::match_collection(
        args[:name].strip,
        collection_entries.values
      )
    elsif @id
      collection_entries[@id]
    end

    if @name && @data = Cache.get_collection_entry(collection_key, @name)
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

  class << self
    def collection
      Cache.get_collection(collection_key.pluralize)
    end

    def find(id)
      new(name: collection[id])
    end
  end
end
