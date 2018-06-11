namespace :ml do
  namespace :similarity do
    task pre: :environment do
      sql = "
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
      result = ActiveRecord::Base.connection.execute(sql)

      File.open('/app/jobs/similarity/summoner_champions.csv', 'w+') do |f|
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

    task post: :environment do
      similarities = File.read('/app/jobs/similarity/champion_similarities.csv')
      similarities.split("\n").map do |similarity|
        similarity.split(',').map(&:to_i)
      end.each do |similarity|
        Cache.set_champion_similarity(similarity.first, similarity[1..-1])
      end
    end
  end
end
