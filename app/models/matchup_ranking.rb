class MatchupRanking < MatchupRole
  validates :name, presence: true, inclusion: { in: CHAMPIONS.values, allow_blank: true }
  validate :matchups_validator

  attr_accessor :name, :matchups, :named_role, :unnamed_role, :expect_user_response

  def initialize(**args)
    args[:name] = CollectionHelper::match_collection(args[:name], CHAMPIONS.values)

    args.each do |key, value|
      instance_variable_set("@#{key}", value)
    end

    @matchups = if @matchup_role = determine_matchup_role
      determine_matchups_by_single_role(@matchup_role)
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
      matchups = Cache.get_champion_matchups(@name, matchup_role, @elo)
      shared_matchups.tap { shared_matchups << matchups if matchups }
    end
    shared_matchups.first if shared_matchups.length == 1
  end

  # Use the unnamed role to try to determine the matchups
  def determine_matchups_by_single_role(role)
    adc = ChampionGGApi::MATCHUP_ROLES[:DUO_CARRY]
    support = ChampionGGApi::MATCHUP_ROLES[:DUO_SUPPORT]

    # ADCs and supports will have both their native role and ADCSUPPORT matchups
    # so use the role to determine which one of those is being asked for
    if role == adc || role == support
      adc_matchups = Cache.get_champion_matchups(@name, adc, @elo)
      return adc_matchups if adc_matchups && role == adc

      support_matchups = Cache.get_champion_matchups(@name, support, @elo)
      return support_matchups if support_matchups && role == support

      return unless adc_matchups || support_matchups
      return Cache.get_champion_matchups(
        @name,
        ChampionGGApi::MATCHUP_ROLES[:ADCSUPPORT],
        @elo
      )
    end

    Cache.get_champion_matchups(@name, role, @elo)
  end

  def matchups_validator
    if errors.messages.empty? && @matchups.nil?
      args = {
        name: @name,
        elo: @elo.humanize,
        named_role: @role1.try(:humanize),
        unnamed_role: @role2.try(:humanize),
        matchup_role: @matchup_role
      }

      if @role1.present? && @role2.present?
        errors[:base] << ApiResponse.get_response({ errors: { matchup_ranking: { empty: :duo_roles } } }, args)
      elsif @role1.present?
        errors[:base] << ApiResponse.get_response({ errors: { matchup_ranking: { empty: :named_role } } }, args)
      elsif @role2.present?
        errors[:base] << ApiResponse.get_response({ errors: { matchup_ranking: { empty: :unnamed_role } } }, args)
      else
        @expect_user_response = true
        errors[:base] << ApiResponse.get_response({ errors: { matchup_ranking: { empty: :no_roles } } }, args)
      end
    end
  end
end
