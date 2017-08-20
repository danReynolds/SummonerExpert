class Item < Collection
  include ActiveModel::Validations

  COLLECTION = Rails.cache.read(collection_key.pluralize)
  ACCESSORS = [
    :name, :sanitizedDescription
  ].freeze
  ACCESSORS.each do |accessor|
    attr_accessor accessor
  end

  validates :name, presence: true, inclusion: COLLECTION.values

  def costs
    @data['gold'].slice('total', 'sell')
  end

  def build
    @data['from'].map { |id| COLLECTION[id.to_i] }
  end
end
