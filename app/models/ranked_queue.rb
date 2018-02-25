class RankedQueue
  include ActiveModel::Validations

  ACCESSORS = [
    :rank, :lp, :wins, :losses, :hot_streak, :name, :inactive
  ].freeze
  ACCESSORS.each do |accessor|
    attr_accessor accessor
  end

  validate :queue_validator

  SOLO_QUEUE = 'RANKED_SOLO_5x5'

  QUEUES = {
    RANKED_SOLO_5x5: 'Solo Queue',
    RANKED_FLEX_SR: 'Flex Queue'
  }.freeze

  def initialize(data)
    return unless @queue = data

    data.slice(*ACCESSORS).each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end

  def winrate
    (@wins.to_f / (@wins + @losses) * 100).round(2)
  end

  def elo
    @queue['tier']
  end

  def lp
    @queue['leaguePoints']
  end

  def name
    QUEUES[@queue['queueType'].to_sym]
  end

  def error_message
    errors.messages.values.map(&:first).en.conjunction(article: false)
  end

  private

  def queue_validator
    unless @queue
      errors[:base] << 'No queue data'
    end
  end
end
