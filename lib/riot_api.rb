module RiotApi
  class RiotApi < ExternalApi
    @api_key = ENV['RIOT_API_KEY']

    class << self
      def get_champions
        Rails.cache.fetch('champions') do
          fetch_response(RIOT_API[:champions])
        end
      end

      def get_champion(name)
        get_champions.detect { |_, data| data[:name] == name }.last
      end

      private

      def fetch_response(endpoint)
        super(endpoint).with_indifferent_access[:data]
      end
    end
  end
end
