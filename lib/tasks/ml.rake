namespace :ml do
  task similarity: :environment do
    query = 'select summoner_id, champion_id, games_played from summoner_stats limit 1000'
    result = ActiveRecord::Base.connection.execute(query)

    File.open('/app/similarity.csv', 'w+') do |f|
      result.values.each do |row|
        f.puts(row.join(','))
      end
    end

    File.open('/app/champions.csv', 'w+') do |f|
      Cache.get_collection(:champions).keys.each do |champion_id|
        f.puts(champion_id)
      end
    end
  end
end
