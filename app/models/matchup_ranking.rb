class MatchupRanking < MatchupRole
  validates :name, presence: true, inclusion: { in: CHAMPIONS.values, allow_blank: true }
  validate :matchups_validator

  attr_accessor :name, :matchups, :named_role, :unnamed_role

  def initialize(**args)
    args[:name] = CollectionHelper::match_collection(args[:name], CHAMPIONS.values)

    args.each do |key, value|
      instance_variable_set("@#{key}", value)
    end

    @matchups = if @matchup_role = determine_matchup_role
      Rails.cache.read(matchups: { name: @name, role: @matchup_role, elo: @elo })
    elsif @role2.present?
      determine_matchups_by_unnamed_role
    else
      determine_matchups_by_shared_roles
    end

    if @matchups
      # Use a single matchup to determine the named champion's role and the
      # unnamed champion's role.
      matchup = @matchups.first
      other_name, matchup_data = matchup

      @named_role = ChampionGGApi::MATCHUP_ROLES[matchup_data[@name]['role'].to_sym]
      @unnamed_role = ChampionGGApi::MATCHUP_ROLES[matchup_data[other_name]['role'].to_sym]
    end
  end

  def error_message
    errors.messages.values.map(&:first).en.conjunction(article: false)
  end

  private

  # If neither role was specified, check if the champion only has one role and
  # return the matchups for that one
  def determine_matchups_by_shared_roles
    shared_matchups = ChampionGGApi::MATCHUP_ROLES.values.inject([]) do |shared_matchups, matchup_role|
      matchups = Rails.cache.read(
        matchups: { name: @name, role: matchup_role, elo: @elo }
      )
      shared_matchups.tap { shared_matchups << matchups if matchups }
    end
    shared_matchups.first if shared_matchups.length == 1
  end

  # Use the unnamed role to try to determine the matchups
  def determine_matchups_by_unnamed_role
    adc = ChampionGGApi::MATCHUP_ROLES[:DUO_CARRY]
    support = ChampionGGApi::MATCHUP_ROLES[:DUO_SUPPORT]

    # ADCs and supports will have both their native role and ADCSUPPORT matchups
    # so use the unnamed role to determine which one of those is being asked for
    if @role2 == adc || @role2 == support
      adc_matchups = Rails.cache.read(
        matchups: { name: @name, role: adc, elo: @elo }
      )
      support_matchups = Rails.cache.read(
        matchups: { name: @name, role: support, elo: @elo }
      )

      return unless adc_matchups || support_matchups
      return adc_matchups if adc_matchups && @role2 == adc
      return support_matchups if support_matchups && @role2 == support
      return Rails.cache.read(
        matchups: { name: @name, role: ChampionGGApi::MATCHUP_ROLES[:ADCSUPPORT], elo: @elo }
      )
    end

    Rails.cache.read( matchups: { name: @name, role: @role2, elo: @elo })
  end

  def matchups_validator
    if errors.messages.empty? && @matchups.nil?
      args = {
        name: @name,
        elo: @elo.humanize,
        named_role: @role1.humanize,
        unnamed_role: @role2.humanize,
        matchup_role: @matchup_role
      }

      if @role1.present? && @role2.present?
        errors[:base] << ApiResponse.get_response({ errors: { matchup_ranking: { empty: :duo_roles } } }, args)
      elsif @role1.present?
        errors[:base] << ApiResponse.get_response({ errors: { matchup_ranking: { empty: :named_role } } }, args)
      elsif @role2.present?
        errors[:base] << ApiResponse.get_response({ errors: { matchup_ranking: { empty: :unnamed_role } } }, args)
      else
        errors[:base] << ApiResponse.get_response({ errors: { matchup_ranking: { empty: :no_roles } } }, args)
      end
    end
  end
end
