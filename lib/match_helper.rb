class MatchHelper
  def self.store_match(match_data)
    team1_params, team2_params = match_data['teams']
    bans = team1_params['bans'] + team2_params['bans']

    ActiveRecord::Base.transaction do
      team1 = Team.create!(
        team_id: team1_params['teamId'],
        tower_kills: team1_params['towerKills'],
        inhibitor_kills: team1_params['inhibitorKills'],
        baron_kills: team1_params['baronKills'],
        dragon_kills: team1_params['dragonKills'],
        riftherald_kills: team1_params['riftHeraldKills']
      )

      team2 = Team.create!(
        team_id: team2_params['teamId'],
        tower_kills: team2_params['towerKills'],
        inhibitor_kills: team2_params['inhibitorKills'],
        baron_kills: team2_params['baronKills'],
        dragon_kills: team2_params['dragonKills'],
        riftherald_kills: team2_params['riftHeraldKills']
      )

      match = Match.create!(
        game_id: match_data['gameId'],
        queue_id: match_data['queueId'],
        season_id: match_data['seasonId'],
        region_id: match_data['platformId'],
        game_duration: match_data['gameDuration'],
        winning_team: team1_params['win'] == 'Win' ? team1 : team2,
        first_blood_team: team1_params['firstBlood'] ? team1 : team2,
        first_tower_team: team1_params['firstTower'] ? team1 : team2,
        first_inhibitor_team: team1_params['firstInhibitor'] ? team1 : team2,
        first_baron_team: team1_params['firstBaron'] ? team1 : team2,
        first_rift_herald_team: team1_params['firstRiftHerald'] ? team1 : team2,
        team1: team1,
        team2: team2
      )

      match_data['participantIdentities'].map.with_index do |summoner_identity, index|
        player_params = summoner_identity['player']
        summoner_params = match_data['participants'][index]
        stats = summoner_params['stats']

        summoner = Summoner.create_with(
          account_id: player_params['accountId'],
          name: player_params['summonerName'],
          region: player_params['currentPlatformId']
        ).find_or_create_by(summoner_id: player_params['summonerId'])

        match.first_blood_summoner = summoner if stats['firstBloodKill']
        match.first_tower_summoner = summoner if stats['firstTowerKill']
        match.first_inhibitor_summoner = summoner if stats['firstInhibitorKill']

        riot_role = summoner_params['timeline']['role']
        riot_lane = summoner_params['timeline']['lane']
        role = ChampionGGApi::ROLES.keys.map(&:to_s).include?(riot_role) ? riot_role : riot_lane

        SummonerPerformance.create!(
          match: match,
          summoner: summoner,
          team: summoner_params['teamId'] == team1.team_id ? team1 : team2,
          participant_id: summoner_identity['participantId'],
          champion_id: summoner_params['championId'],
          spell1_id: summoner_params['spell1Id'],
          spell2_id: summoner_params['spell2Id'],
          kills: stats['kills'],
          deaths: stats['deaths'],
          assists: stats['assists'],
          role: role,
          largest_killing_spree: stats['largestKillingSpree'],
          total_killing_sprees: stats['killingSprees'],
          double_kills: stats['doubleKills'],
          triple_kills: stats['tripleKills'],
          quadra_kills: stats['quadraKills'],
          penta_kills: stats['pentaKills'],
          total_damage_dealt: stats['totalDamageDealt'],
          magic_damage_dealt: stats['magicDamageDealt'],
          physical_damage_dealt: stats['physicalDamageDealt'],
          true_damage_dealt: stats['trueDamageDealt'],
          largest_critical_strike: stats['largestCriticalStrike'],
          total_damage_dealt_to_champions: stats['totalDamageDealtToChampions'],
          magic_damage_dealt_to_champions: stats['magicDamageDealtToChampions'],
          physical_damage_dealt_to_champions: stats['physicalDamageDealtToChampions'],
          true_damage_dealt_to_champions: stats['trueDamageDealtToChampions'],
          total_healing_done: stats['totalHeal'],
          vision_score: stats['visionScore'],
          cc_score: stats['timeCCingOthers'],
          gold_earned: stats['goldEarned'],
          turrets_killed: stats['turretKills'],
          inhibitors_killed: stats['inhibitorKills'],
          total_minions_killed: stats['totalMinionsKilled'],
          neutral_minions_killed: stats['neutralMinionsKilled'],
          neutral_minions_killed_team_jungle: stats['neutralMinionsKilledTeamJungle'],
          neutral_minions_killed_enemy_jungle: stats['neutralMinionsKilledEnemyJungle'],
          vision_wards_bought: stats['visionWardsBoughtInGame'],
          sight_wards_bought: stats['sightWardsBoughtInGame'],
          wards_killed: stats['wardsKilled'],
          wards_placed: stats['wardsPlaced'],
          item0_id: stats['item0'],
          item1_id: stats['item1'],
          item2_id: stats['item2'],
          item3_id: stats['item3'],
          item4_id: stats['item4'],
          item5_id: stats['item5'],
          item6_id: stats['item6'],
          ban: Ban.new(champion_id: bans[index]['championId'])
        )
      end
      match.save!
    end
  end
end
