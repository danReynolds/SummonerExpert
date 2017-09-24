class Summoner
  include ActiveModel::Validations
  include RiotApi

  ACCESSORS = [
    :name, :region, :queue, :id
  ].freeze
  ACCESSORS.each do |accessor|
    attr_accessor accessor
  end

  validates :id, numericality: { only_integer: true, greater_than: 0 }
  validates :name, presence: true
  validates :region, inclusion: RiotApi::REGIONS
  validate :matchup_validator

  def initialize(args)
    args.slice(*ACCESSORS).each do |key, value|
      instance_variable_set("@#{key}", value)
    end

    @id = Cache.get_or_set_summoner_id(@name, @region) do
      RiotApi.get_summoner_id(name: @name, region: @region)
    end

    if @queue_name = args[:with_queue]
      @queue = RankedQueue.new(Cache.get_or_set_summoner_queues(@name, @region) do
        RiotApi.get_summoner_queues(id: @id, region: @region)
      end[@queue_name])
    end
  end

  def error_message
    errors.messages.values.map(&:first).en.conjunction(article: false)
  end

  private

  def matchup_validator
    if @queue && @queue.invalid?
      errors[:base] << ApiResponse.get_response(
        { errors: { summoner: :not_active } },
        { name: @name, queue: RankedQueue::QUEUES[@queue_name.to_sym] }
      )
    end
  end
end
