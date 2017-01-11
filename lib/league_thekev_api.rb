module LeagueThekevApi
  class LeagueThekevApi < ExternalApi
    @api_key = ENV['LEAGUE_THEKEV_API']

    class << self
      def get_item(id)
        fetch_response("#{LEAGUE_THEKEV_API[:item]}/#{id}/efficiency")
      end
    end
  end
end
