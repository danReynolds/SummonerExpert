require './lib/matcher.rb'

module RiotApi
  class RiotApi < ExternalApi
    include Matcher

    @api_key = ENV['RIOT_API_KEY']
    @api = load_api('riot_api')

    # Limited to 500 requests per 10 seconds, 30000 requests per 10 minutes
    RIOT_API_RATE_LIMIT = 500

    # Default tags to use for requesting champions
    DEFAULT_TAGS = [:allytips, :blurb, :enemytips, :info, :spells, :stats, :tags, :lore]

    # Current season as defined by season indicated in matches API
    ACTIVE_SEASON = 9

    # Matches are based off of Ranked Solo Queue
    RANKED_QUEUE_ID = 420

    # Number of items making up a completed build
    COMPLETED_BUILD_SIZE = 6

    # API Error Codes
    RATE_LIMIT_EXCEEDED = 429
    INTERNAL_SERVER_ERROR = 500
    SERVICE_UNAVAILABLE = 503
    BAD_REQUEST = 400
    FORBIDDEN = 403
    NOT_FOUND = 404
    ERROR_CODES = [
      RATE_LIMIT_EXCEEDED,
      INTERNAL_SERVER_ERROR,
      SERVICE_UNAVAILABLE,
      BAD_REQUEST,
      FORBIDDEN,
      NOT_FOUND
    ]
    IGNORE_CODES = [
    ]

    # Constants related to the Riot Api
    TOP = 'Top'.freeze
    JUNGLE = 'Jungle'.freeze
    SUPPORT = 'Support'.freeze
    ADC = 'ADC'.freeze
    MIDDLE = 'Middle'.freeze
    ROLES = [TOP, JUNGLE, SUPPORT, ADC, MIDDLE]

    REGIONS = %w(BR1 EUN1 EUW1 JP1 KR LA1 LA2 NA1 NA2 OC1 RU TR1)

    STATS = {
      armor: 'armor',
      attackdamage: 'attack damage',
      attackrange: 'attack range',
      crit: 'critical chance',
      hp: 'health',
      hpregen: 'health regeneration',
      movespeed: 'movement speed',
      mp: 'mana',
      mpregen: 'mana regeneration',
      spellblock: 'magic resist'
    }.freeze

    # Summoner champion position details
    POSITION_DETAILS = {
      kills: 'kills',
      deaths: 'deaths',
      assists: 'assists',
      largest_killing_spree: 'largest killing spree',
      total_killing_sprees: 'total killing sprees',
      double_kills: 'double kills',
      triple_kills: 'triple kills',
      quadra_kills: 'quadra kills',
      penta_kills: 'penta kills',
      total_damage_dealt: 'total damage dealt',
      magic_damage_dealt: 'magic damage dealt',
      physical_damage_dealt: 'physical damage dealt',
      true_damage_dealt: 'true damage dealt',
      largest_critical_strike: 'largest critical strike',
      total_damage_dealt_to_champions: 'total damage dealt to champions',
      magic_damage_dealt_to_champions: 'magic damage dealt to champions',
      physical_damage_dealt_to_champions: 'physical damage dealt to champions',
      true_damage_dealt_to_champions: 'true damage dealt to champions',
      total_healing_done: 'total healing done',
      vision_score: 'vision score',
      cc_score: 'cc score',
      gold_earned: 'gold',
      turrets_killed: 'towers destroyed',
      inhibitors_killed: 'inhibitors destroyed',
      total_minions_killed: 'creep score',
      vision_wards_bought: 'vision wards',
      sight_wards_bought: 'sight wards',
      wards_placed: 'wards placed',
      wards_killed: 'wards destroyed',
      neutral_minions_killed: 'jungle minions killed',
      neutral_minions_killed_team_jungle: 'own jungle minions killed',
      neutral_minions_killed_enemy_jungle: 'enemy jungle minions killed'
    }

    POSITION_METRICS = {
      count: 'games played',
      KDA: 'KDA',
      winrate: 'win rate'
    }

    class << self
      def get_champions(**args)
        args[:tags] ||= DEFAULT_TAGS.map do |tag|
          "&tags=#{tag}"
        end.join('')

        url = replace_url(@api[:champions], args)
        fetch_response(url)
      end

      def get_items
        fetch_response(@api[:items])
      end

      def get_spells
        fetch_response(@api[:spells])
      end

      def get_match(args)
        url = replace_url(@api[:match], args)
        fetch_response(url, ERROR_CODES, IGNORE_CODES)
      end

      def get_recent_matches(args)
        url = replace_url(@api[:summoner][:recent_matches], args)
        fetch_response(url)
      end

      def get_matchups(args)
        url = replace_url(@api[:summoner][:matchups], args)
        fetch_response(url)
      end

      def get_summoner_queues(args)
        url = replace_url(@api[:summoner][:queues], args)
        return unless queue_stats = fetch_response(url)

        queue_stats.inject({}) do |queues, queue_stat|
          queues.tap do
            queues[queue_stat['queueType']] = queue_stat.slice(
              'leaguePoints', 'wins', 'losses', 'rank', 'hotStreak', 'inactive',
              'tier', 'queueType'
            ).with_indifferent_access
          end
        end
      end

      def get_summoner_id(args)
        name = URI.encode(args[:name])
        url = "#{replace_url(@api[:summoner][:id], args)}/#{name}"
        return unless response = fetch_response(url)
        response['id']
      end
    end
  end
end
