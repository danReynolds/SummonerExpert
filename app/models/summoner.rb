class Summoner
  include ActiveModel::Validations
  include RiotApi
  attr_accessor :id, :name, :region

  validates :id, numericality: { only_integer: true, greater_than: 0 }
  validates :name, presence: true
  validates :region, inclusion: RiotApi::REGIONS

  def initialize(**args)
    args.each do |key, value|
      instance_variable_set("@#{key}", value)
    end

    @id = RiotApi.get_summoner_id(name: @name, region: @region) unless @id
  end

  def error_message
    errors.messages.values.map(&:first).en.conjunction(article: false)
  end
end
