module ChampionGGApi
  class ChampionGGApi < ExternalApi
    @api_key = ENV['CHAMPION_GG_API_KEY']

    class << self
      def get_champion(name)
        fetch_response("#{CHAMPION_GG_API[:champion]}/#{name}")
      end
    end
  end
end
