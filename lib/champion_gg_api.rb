class ChampionGGApi < ExternalApi
  @api_key = ENV['CHAMPION_GG_API_KEY']
  @api = load_api('champion_gg_api')

  # ELO Options
  ELOS = {
    BRONZE: 'BRONZE',
    SILVER: 'SILVER',
    GOLD: 'GOLD',
    PLATINUM: 'PLATINUM',
    PLATINUM_PLUS: 'PLATINUM_PLUS'
  }.freeze

  # Metric Options
  # for builds and ability order performance in a role
  METRICS = {
    highestWinrate: 'highest win rate',
    highestCount: 'most frequent'
  }

  # Role Options
  ROLES = {
    TOP: 'TOP',
    MIDDLE: 'MIDDLE',
    JUNGLE: 'JUNGLE',
    DUO_CARRY: 'ADC', # Champion is playing ADC
    DUO_SUPPORT: 'SUPPORT' # Champion is playing Support
  }.freeze

  # Matchup Role Options
  # Who you are comparing the champion with/against in the matchup
  MATCHUP_ROLES = {
    TOP: 'TOP',
    JUNGLE: 'JUNGLE',
    MIDDLE: 'MIDDLE',
    SYNERGY: 'SYNERGY', # Matchup compares the champion to its lane partner
    ADCSUPPORT: 'ADCSUPPORT', # Matchup compares the champion to its bot lane opponent of the other role
    DUO_CARRY: 'ADC', # Matchup compares the champion as an ADC to the opposing ADC
    DUO_SUPPORT: 'SUPPORT' # Matchup compares the champion as a Support to the opposing Support
  }.freeze

  MATCHUP_POSITIONS = {
    kills: 'kills',
    deaths: 'deaths',
    minionsKilled: 'CS',
    goldEarned: 'gold',
    winrate: 'win rate',
    totalDamageDealtToChampions: 'total damage dealt to champions',
    assists: 'assists',
    killingSprees: 'killing sprees'
  }.freeze

  # Champion Positions currently being ranked and cached
  POSITIONS = {
    deaths: 'deaths',
    winRates: 'win rate',
    minionsKilled: 'creep score',
    banRates: 'ban rate',
    assists: 'assists',
    kills: 'kills',
    playRates: 'play rate',
    damageDealt: 'damage dealt',
    goldEarned: 'gold earned',
    overallPerformanceScore: 'overall performance',
    totalHeal: 'healing done',
    killingSprees: 'average killing sprees',
    totalDamageTaken: 'total damage taken',
    averageGamesScore: 'average games played',
    # These 2 positions are useful internally but are not requested by users
    totalPositions: '',
    previousOverallPerformanceScore: ''
  }.freeze

  # Champion position details
  POSITION_DETAILS = {
    winRate: 'win rate',
    kills: 'kills',
    totalDamageTaken: 'total damage taken',
    wardsKilled: 'wards killed',
    averageGames: 'games per summoner',
    largestKillingSpree: 'largest killing spree',
    assists: 'assists',
    playRate: 'play rate',
    gamesPlayed: 'total games played',
    percentRolePlayed: 'role percentage',
    goldEarned: 'gold earned',
    deaths: 'deaths',
    wardPlaced: 'wards placed',
    banRate: 'ban rate',
    minionsKilled: 'creep score'
  }.freeze

  class << self
    def get_champion_roles(**args)
      url = replace_url(@api[:champion_roles], args)
      fetch_response(url)
    end

    def get_site_information
      fetch_response(@api[:site_information])
    end
  end
end
