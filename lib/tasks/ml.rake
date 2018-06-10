namespace :ml do
  namespace :similarity do
    task initialize: :environment do
      sql = "
      create materialized view summoner_champions as
          with recent_performances as (
            select summoner_id, champion_id, id from summoner_performances
            order by id desc
            limit 10000000
          )
          select
              summoner_id,
              champion_id,
              count(*) as games_played
          from recent_performances
          group by summoner_id, champion_id
          order by games_played desc
      "
      ActiveRecord::Base.connection.execute(sql)
    end

    task run: :environment do
      query = 'select summoner_id, champion_id, games_played from summoner_stats limit 1000'
      result = ActiveRecord::Base.connection.execute(query)

      File.open('/app/jobs/similarity/similarity.csv', 'w+') do |f|
        result.values.each do |row|
          f.puts(row.join(','))
        end
      end

      File.open('/app/jobs/similarity/champions.csv', 'w+') do |f|
        Cache.get_collection(:champions).keys.each do |champion_id|
          f.puts(champion_id)
        end
      end
    end
  end
end
