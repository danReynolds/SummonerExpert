module ChampionGGApi
  class ChampionGGApi < ExternalApi
    @api_key = ENV['CHAMPION_GG_API_KEY']
    @api = load_api('champion_gg_api')

    class << self
      def get_champion(args)
        url = replace_url(@api[:champion], args)
        a = fetch_response(url)
      end
    end
  end
end
