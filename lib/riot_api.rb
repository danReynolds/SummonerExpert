require './lib/matcher.rb'

module RiotApi
  class RiotApi < ExternalApi
    include Matcher

    @api_key = ENV['RIOT_API_KEY']
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

    class << self
      def get_champions
        fetch_response(RIOT_API[:champions])
      end

      def get_items
        fetch_response(RIOT_API[:items])
      end

      def get_champion(name)
        Rails.cache.read(champions: name) || match_champion(name)
      end

      private

      def match_champion(name)
        matcher = Matcher::Matcher.new(name)
        champions = Rails.cache.read(:champions).to_a

        if match = matcher.find_match(champions, SIMILARITY_THRESHOLD, :last)
          Rails.cache.read(champions: match.result.last)
        end
      end

      def fetch_response(endpoint)
        super(endpoint).with_indifferent_access[:data]
      end
    end
  end
end
