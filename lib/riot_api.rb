module RiotApi
  class RiotApi < ExternalApi
    @api_key = ENV['RIOT_API_KEY']

    class << self
      def get_champions
        if Rails.cache.exist?(:champions)
          Rails.cache.read(:champions)
        else
          response = fetch_response(RIOT_API[:champions])
          Rails.cache.write(:champions, response)
        end
        return Rails.cache.read(:champions)
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
