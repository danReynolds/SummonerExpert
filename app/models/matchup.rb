class Matchup < MatchupRole
  validates :name1, presence: true, inclusion: { in: CHAMPIONS.values, allow_blank: true }
  validates :name2, presence: true, inclusion: { in: CHAMPIONS.values, allow_blank: true }
  validate :matchup_validator

  attr_accessor :name1, :name2, :expect_user_response

  def initialize(**args)
    args[:name1] = CollectionHelper::match_collection(args[:name1], CHAMPIONS.values)
    args[:name2] = CollectionHelper::match_collection(args[:name2], CHAMPIONS.values)

    args.each do |key, value|
      instance_variable_set("@#{key}", value)
    end

    @matchup_role = determine_matchup_role
    @matchup = if @matchup_role
      matchups = Cache.get_champion_matchups(@name1, @matchup_role, @elo)
      matchups[@name2] if matchups
    else
      @shared_matchups = find_shared_matchups
      @shared_matchups.first if @shared_matchups.length == 1
    end
  end

  def position(position_name, champion_name)
    @matchup[champion_name][position_name]
  end

  def error_message
    errors.messages.values.map(&:first).en.conjunction(article: false)
  end

  private

  # Find all shared roles between the champions and return the shared roles
  def find_shared_matchups
    ChampionGGApi::MATCHUP_ROLES.values.inject([]) do |shared_matchups, matchup_role|
      matchups = Cache.get_champion_matchups(@name1, matchup_role, @elo)
      shared_matchups.tap do
        if matchups && matchup = matchups[@name2]
          shared_matchups << matchup
        end
      end
    end
  end

  # Add manual validation errors if there is no matchup based on the roles specified
  def matchup_validator
    if errors.messages.empty? && @matchup.nil?
      args = {
        name1: @name1,
        name2: @name2,
        elo: @elo.humanize,
        role1: @role1.try(:humanize),
        role2: @role2.try(:humanize),
        matchup_role: @matchup_role.try(:humanize)
      }

      if @role1.present? && @role2.present?
        errors[:base] << ApiResponse.get_response({ errors: { matchups: :duo_role_no_matchup } }, args)
      elsif @matchup_role
        errors[:base] << ApiResponse.get_response({ errors: { matchups: :solo_role_no_matchup } }, args)
      elsif @shared_matchups.length > 1
        @expect_user_response = true
        errors[:base] << ApiResponse.get_response({ errors: { matchups: :multiple_shared_roles } }, args)
      elsif @shared_matchups.length == 0
        errors[:base] << ApiResponse.get_response({ errors: { matchups: :no_shared_roles } }, args)
      end
    end
  end
end
