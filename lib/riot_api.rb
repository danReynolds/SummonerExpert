module RiotApi
  class RiotApi < ExternalApi
    @api_key = ENV['RIOT_API_KEY']

    class << self
      def get_champions
        fetch_response(RIOT_API[:champions])
      end

      def get_champion(name)
        Rails.cache.read(champions: name)
      end

      private

      def fetch_response(endpoint)
        super(endpoint).with_indifferent_access[:data]
      end
    end
  end
end
