class Item < Collection
  include ActiveModel::Validations
  COLLECTION = Rails.cache.read(:items).values.map { |data| data[:name] }
  ACCESSORS = [
    :cost_analysis, :name, :description
  ].freeze
  ACCESSORS.each do |accessor|
    attr_accessor accessor
  end

  validates :name, presence: true
  validates :name, inclusion: { in: COLLECTION }
end
