require './lib/matcher.rb'

module RiotApi
  class RiotApi < ExternalApi
    include Matcher

    @api_key = ENV['RIOT_API_KEY']
    @api = load_api('riot_api')

    # Default tags to use for requesting champions
    DEFAULT_TAGS = [:allytips, :blurb, :enemytips, :info, :spells, :stats, :tags, :lore]

    # Constants related to the Riot Api
    TOP = 'Top'.freeze
    JUNGLE = 'Jungle'.freeze
    SUPPORT = 'Support'.freeze
    ADC = 'ADC'.freeze
    MIDDLE = 'Middle'.freeze
    ROLES = [TOP, JUNGLE, SUPPORT, ADC, MIDDLE]

    QUEUES = {
      RANKED_SOLO_5x5: 'Solo Queue',
      RANKED_FLEX_SR: 'Flex Queue'
    }.freeze

    REGIONS = %w(br1 eun1 euw1 jp1 kr la1 la2 na1 oc1 ru tr1)

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

      def get_summoner_champions(args)
        url = "#{replace_url(@api[:summoner][:champions], args)}?season=#{@api[:season]}"
        fetch_response(url)[:champions].reject { |champ| champ[:id].zero? }
      end

      def get_summoner_stats(args)
        url = replace_url(@api[:summoner][:description], args)
        return unless queue_stats = fetch_response(url)

        queue_stats.inject({}) do |queues, queue_stat|
          queues.tap do
            queues[queue_stat['queueType']] = queue_stat.slice(
              'leaguePoints', 'wins', 'losses', 'rank', 'hotStreak', 'inactive',
              'tier'
            )
          end
        end
      end

      def get_summoner_id(args)
        Rails.cache.fetch(name: args[:name], region: args[:region]) do
          name = URI.encode(args[:name])
          url = "#{replace_url(@api[:summoner][:id], args)}/#{name}"
          return unless response = fetch_response(url)
          response['id']
        end
      end
    end
  end
end
