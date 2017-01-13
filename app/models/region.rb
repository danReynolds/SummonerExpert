class Region
  include ActiveModel::Validations
  attr_accessor :region

  REGIONS = %w(br eune euw jp kr lan las na oce ru tr).freeze

  validates :region, inclusion: { in: REGIONS }

  def initialize(attributes = {})
    @region = attributes[:region]
  end

  def error_message
    errors.messages.map do |key, value|
      "#{key} #{value.first}"
    end.en.conjunction(article: false)
  end
end
