class MatchWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker
  include RiotApi

  sidekiq_throttle({
   threshold: { limit: 450, period: 10.seconds }
  })

  def perform(game_id, fixup = false)
    # Skip if the game is somehow already saved
    unless Match.find_by(game_id: game_id)
      match_data = RiotApi.get_match(id: game_id)
      # Check that it is a ranked game for the current season
      if (match_data && match_data['queueId'] == RiotApi::RANKED_QUEUE_ID &&
        match_data['seasonId'] == RiotApi::ACTIVE_SEASON)
        Raven.capture_exception(Exception.new("Found on retry: #{game_id}")) if fixup
        MatchHelper.store_match(match_data)
      end
    end
  end
end
