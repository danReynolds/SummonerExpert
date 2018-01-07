class DataDog
  @client = Dogapi::Client.new(ENV['DATA_DOG_KEY']) if ENV['DATA_DOG_KEY']

  RETRY_LIMIT = 5
  HOST = 'ServerManager'
  EVENTS = {
    CHAMPIONGG_CHAMPION_PERFORMANCE: 'Champion GG Performance Event',
    RIOT_CHAMPIONS: 'Riot Champions Event',
    RIOT_ITEMS: 'Riot Items Event',
    RIOT_SPELLS: 'Riot Spells Event',
    RIOT_MATCHES: 'Riot Matches Event',
    RIOT_MATCHES_ERROR: 'Riot Matches Error Event',
    RIOT_MATCHES_FIX: 'Riot Matches Fix Event'
  }

  class << self
    def event(type, **args)
      RETRY_LIMIT.times do
        begin
          @client.emit_event(
            Dogapi::Event.new("#{type}. #{args}"),
            host: HOST
          )
          return
        rescue Exception => e
          puts "No work #{e}"
        end
      end
    end
  end
end
