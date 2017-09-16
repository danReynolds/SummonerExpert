class RolePerformance
  include ActiveModel::Validations

  validates :elo, presence: true
  validates :name, presence: true
  validate :role_performance_validator

  attr_accessor :elo, :role, :name, :expect_user_response

  # Accessors coming directly from the data object
  RELAY_ACCESSORS = [
    :winRate, :kills, :totalDamageTaken, :wardsKilled, :averageGames,
    :largestKillingSpree, :assists, :playRate, :gamesPlayed, :percentRolePlayed,
    :goldEarned, :deaths, :wardPlaced, :banRate, :minionsKilled
  ].freeze
  RELAY_ACCESSORS.each do |accessor|
    attr_accessor accessor
  end
  MAX_ABILITY_LEVEL = 5
  ABILITY_VARIANT_SIZE = 3

  def initialize(**args)
    args.each do |key, value|
      instance_variable_set("@#{key}", value)
    end

    if @role.present?
      @role_performance = Rails.cache.read(args)
    else
      role_performances = ChampionGGApi::ROLES.values.map do |role|
        { role: role, role_performance: Rails.cache.read(args.merge(role: role)) }
      end.reject { |role_entry| role_entry[:role_performance].nil? }

      if role_performances.length == 1
        role_entry = role_performances.first
        @role_performance = role_entry[:role_performance]
        @role = role_entry[:role]
      end
    end

    if @role_performance
      RELAY_ACCESSORS.each do |accessor|
        instance_variable_set("@#{accessor}", @role_performance[accessor.to_s])
      end
    end
  end

  def ability_order(metric)
    order = {}
    abilities = @role_performance['hashes']['skillorderhash'][metric]['hash']
      .split('-')[1..-1]

    order[:max_order] = abilities.inject(Hash.new(0).merge!({ max_order: [] })) do |acc, ability|
      acc[ability] += 1
      acc.tap do
        acc[:max_order] << ability if acc[ability] == MAX_ABILITY_LEVEL
      end
    end[:max_order]

    abilities.size.times do |i|
      ability_subset = abilities.first(i)
      if ability_subset.uniq.size == ABILITY_VARIANT_SIZE
        order[:start_order] = ability_subset
        break
      end
    end

    order
  end

  def item_ids(metric)
    @role_performance['hashes']['finalitemshashfixed'][metric]['hash'].split('-')[1..-1].map(&:to_i)
  end

  def position(position_name)
    {
      position: @role_performance['positions'][position_name.to_s],
      total_positions: @role_performance['positions']['totalPositions']
    }
  end

  def kda
    {
      kills: @kills,
      deaths: @deaths,
      assists: @assists
    }
  end

  def error_message
    errors.messages.values.map(&:first).en.conjunction(article: false)
  end

  private

  def role_performance_validator
    args = { name: @name, elo: @elo.humanize, role: @role.humanize }

    if errors.empty? && @role_performance.nil?
      if @role.present?
        errors[:base] << ApiResponse.get_response({ errors: { role_performance: :does_not_play } }, args)
      else
        @expect_user_response = true
        errors[:base] << ApiResponse.get_response({ errors: { role_performance: :plays_multiple_roles } }, args)
      end
    end
  end
end
