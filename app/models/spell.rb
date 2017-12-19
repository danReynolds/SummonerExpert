class Spell < Collection
  include ActiveModel::Validations

  COLLECTION = Cache.get_collection(collection_key.pluralize)
  ACCESSORS = [
    :name, :sanitizedDescription, :cooldown, :range, :summonerLevel, :id, :modes
  ].freeze
  ACCESSORS.each do |accessor|
    attr_accessor accessor
  end

  validates :name, presence: true, inclusion: COLLECTION.values
end
