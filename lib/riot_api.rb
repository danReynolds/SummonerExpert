require './lib/matcher.rb'

module RiotApi
  class RiotApi < ExternalApi
    include Matcher

    @api_key = ENV['RIOT_API_KEY']
    @api = load_api('riot_api')

    # Constants related to the Riot Api
    SIMILARITY_THRESHOLD = 0.7
    TOP = 'Top'.freeze
    JUNGLE = 'Jungle'.freeze
    SUPPORT = 'Support'.freeze
    ADC = 'ADC'.freeze
    MIDDLE = 'Middle'.freeze
    ROLES = [TOP, JUNGLE, SUPPORT, ADC, MIDDLE]
    ABILITIES = {
      first: 0,
      q: 0,
      second: 1,
      w: 1,
      third: 2,
      e: 2,
      r: 3,
      ultimate: 3,
      fourth: 3
    }.freeze
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
    QUEUE = {
      RANKED_SOLO_5x5: 'Solo Queue',
      RANKED_FLEX_SR: 'Flex Queue'
    }.freeze

    class << self
      def get_champions
        fetch_response(@api[:champions])
      end

      def get_items
        fetch_response(@api[:items])
      end

      def get_summoner_champions(args)
        url = "#{replace_url(@api[:summoner][:champions], args)}?season=#{@api[:season]}"
        summoner_champions = fetch_response(url)[:champions]

        summoner_champions.reject { |champ| champ[:id].zero? }.sort do |champ1, champ2|
          champ2[:stats][:totalSessionsPlayed] <=> champ1[:stats][:totalSessionsPlayed]
        end
      end

      def get_summoner_stats(args)
        url = replace_url(@api[:summoner][:ranked], args)
        id = args[:id]
        fetch_response(url)[id].map do |division|
          division[:entries].detect do |entry|
            entry[:playerOrTeamId] == id
          end.merge(
            queue: RiotApi::QUEUE[division[:queue].to_sym],
            tier: division[:tier].downcase.capitalize
          )
        end
      end

      def get_summoner_id(args)
        url = "#{replace_url(@api[:summoner][:id], args)}/#{args[:name]}"
        fetch_response(url)[args[:name]][:id].to_s
      end

      def get_item(name)
        Rails.cache.read(items: name) || match_collection(name, :items)
      end

      def get_champion(name)
        Rails.cache.read(champions: name) || match_collection(name, :champions)
      end

      private

      def match_collection(name, collection_key)
        matcher = Matcher::Matcher.new(name)
        collection = Rails.cache.read(collection_key).to_a
        search_key = Hash.new

        if match = matcher.find_match(collection, SIMILARITY_THRESHOLD, :last)
          search_key[collection_key] = match.result.last
          Rails.cache.read(search_key)
        end
      end
    end
  end
end
