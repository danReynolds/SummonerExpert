class Summoner
  include ActiveModel::Validations
  attr_accessor :id, :name

  validates :id, numericality: { only_integer: true, greater_than: 0 }
  validates :name, presence: true

  def initialize(attributes = {})
    @id = attributes[:id]
    @name = attributes[:name]
  end

  def error_message
    errors.messages.map do |key, value|
      "#{key} #{value.first}"
    end.en.conjunction(article: false)
  end
end
