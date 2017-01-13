module ChampionGGApi
  class ChampionGGApi < ExternalApi
    @api_key = ENV['CHAMPION_GG_API_KEY']
    @api = load_api('champion_gg_api')

    class << self
      def get_champion(name)
        fetch_response("#{@api[:champion]}/#{name}")
      end
    end
  end
end
