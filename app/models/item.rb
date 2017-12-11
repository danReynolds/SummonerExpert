class Item < Collection
  include ActiveModel::Validations

  COLLECTION = Cache.get_collection(collection_key.pluralize)
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

  def complete?
    into = @data['into']
    # Hack to determine if an item is complete. Items that build into Ornn items
    # can still be considered complete. Only Ornn upgrades cost > 2500 and
    # only build from one item so use that to determine completion
    into.nil? || (into.length == 1 &&
      Item.new(name: COLLECTION[into.first.to_i]).costs['total'] > 2500)
  end

  def build
    @data['from'].map { |id| COLLECTION[id.to_i] }
  end
end
