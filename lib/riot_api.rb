module RiotApi
  class RiotApi < ExternalApi

    @api_key = ENV['RIOT_API_KEY']
    SIMILARITY_THRESHOLD = 0.7

    class << self
      def get_champions
        fetch_response(RIOT_API[:champions])
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
