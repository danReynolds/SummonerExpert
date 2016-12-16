module RiotApi
  class RiotApi
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
        append_symbol = endpoint.include?('?') ? '&' : '?'
        uri = URI("#{endpoint}#{append_symbol}api_key=#{ENV['RIOT_API_KEY']}")
        JSON.parse(Net::HTTP.get(uri)).with_indifferent_access[:data]
      end
    end
  end
end
