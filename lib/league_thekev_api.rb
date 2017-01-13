module LeagueThekevApi
  class LeagueThekevApi < ExternalApi
    @api_key = ENV['LEAGUE_THEKEV_API']
    @api = load_api('league_thekev_api')

    class << self
      def get_item(args)
        url = replace_url(@api[:item], args)
        fetch_response(url).first[:attributes]
      end
    end
  end
end
