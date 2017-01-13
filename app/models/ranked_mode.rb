class RankedMode
  include ActiveModel::Validations
  attr_accessor :mode

  MODES = {
    RANKED_SOLO_5x5: 'Solo Queue',
    RANKED_FLEX_SR: 'Flex Queue'
  }.freeze

  validates :mode, inclusion: { in: MODES.values }

  def initialize(attributes = {})
    @mode = MODES[attributes[:mode]]
  end

  def error_message
    errors.messages.map do |key, value|
      "#{key} #{value.first}"
    end.en.conjunction(article: false)
  end
end
