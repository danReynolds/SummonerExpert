module LeagueThekevApi
  class LeagueThekevApi < ExternalApi
    @api_key = ENV['LEAGUE_THEKEV_API']
    @api = load_api('league_thekev_api')

    class << self
      def get_item(id)
        fetch_response("#{@api[:item]}/#{id}/efficiency")
      end
    end
  end
end
