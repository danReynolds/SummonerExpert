# Base class for models that need to establish a matchup role such as
# Matchup for named champion matchups and Matchup Ranking for rankings against a named
# champion.
class MatchupRole
  include CollectionHelper
  include ActiveModel::Validations
  CHAMPIONS = Cache.get_collection(:champions)

  attr_accessor :matchup_role, :role1, :role2, :elo

  validates :elo, presence: true

  def role_type
    if @matchup_role == ChampionGGApi::MATCHUP_ROLES[:SYNERGY]
      :synergy
    elsif @role1 == @role2 || @role1.blank? || @role2.blank?
      :solo_role
    else
      :duo_role
    end
  end

  protected

  def determine_matchup_role
    synergy = ChampionGGApi::MATCHUP_ROLES[:SYNERGY]
    adc = ChampionGGApi::MATCHUP_ROLES[:DUO_CARRY]
    support = ChampionGGApi::MATCHUP_ROLES[:DUO_SUPPORT]
    adc_support = ChampionGGApi::MATCHUP_ROLES[:ADCSUPPORT]

    if @role1 == synergy || @role2 == synergy
      synergy
    elsif (@role1 == adc_support || @role2 == adc_support) ||
      (@role1 == adc && @role2 == support) || (@role1 == support && @role2 == adc)
      adc_support
    else
      [@role1, @role2].find(&:present?)
    end
  end
end
