class MatchHelper
  class << self
    def store_match(match_data)
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
          # If there is no role present, use the lane as a proxy for role
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
        analyze_team_roles(match.team1)
        analyze_team_roles(match.team2)
        match.save!
      end
    end

    def team_roles_missing?(performances)
      roles = ChampionGGApi::ROLES.keys.map(&:to_s)
      (performances.map(&:role).uniq & roles).length != roles.length
    end

    def analyze_team_roles(team)
      performances = team.summoner_performances
      return unless team_roles_missing?(performances)
      fix_team_roles(performances)
    end

    # Roles may be incorrectly returned from Riot, in which case an attempt is made to correct
    # the roles based on by order:
    # - Normal roles for that champion
    # - Unique spell for roles that have them
    # - Most assists if support
    # - Random
    def fix_team_roles(undetermined_performances)
      undetermined_roles = []
      performances_by_role = ChampionGGApi::ROLES.keys.map(&:to_s).inject(Hash.new([])) do |acc, role|
        performances = undetermined_performances.select { |performance| performance.role == role }
        if performances.length == 1
          undetermined_performances -= [performances.first]
        else
          undetermined_roles << role
        end
        acc.tap { acc[role] = performances }
      end

      undetermined_roles.each do |role|
        performances_for_role = performances_by_role[role]
        determined_performance = if performances_for_role.length > 1
          determine_performance_for_role(role, performances_for_role)
        else
          performance = determine_performance_for_role(role, undetermined_performances)
        end

        if determined_performance
          undetermined_performances -= [determined_performance]
          performances_by_role[determined_performance.role] -= [determined_performance]
          undetermined_roles -= [role]
          determined_performance.update!(role: role)
        end
      end

      # If after trying to determine roles there are still some left, assign them randomly
      undetermined_performances.each_with_index do |performance, i|
        performance.update!(role: undetermined_roles[i])
      end
    end

    def determine_performance_for_role(undetermined_role, possible_performances)
      spell_indicators = {
        JUNGLE: Spell.new(name: 'Smite').id,
        DUO_CARRY: Spell.new(name: 'Heal').id,
        DUO_SUPPORT: Spell.new(name: 'Exhaust').id
      }

      return possible_performances.first if possible_performances.length == 1

      # First determine if the champion played normally plays the undetermined role
      champions = Cache.get_collection(:champions)
      performances = possible_performances.select do |performance|
        champion = champions[performance.champion_id]
        Cache.get_champion_role_performance(champion, undetermined_role, ChampionGGApi::ELOS[:PLATINUM_PLUS])
      end

      return performances.first if performances.length == 1

      # Next determine if only one performance has the role's associated summoner spell
      performances = possible_performances.select do |performance|
        associated_spell_id = spell_indicators[undetermined_role.to_sym]
        associated_spell_id.nil? || (performance.spell1_id == associated_spell_id ||
          performance.spell2_id == associated_spell_id)
      end

      return performances.first if performances.length == 1

      # Finally use assists as the metric if the role is support
      if (undetermined_role.to_sym == :DUO_SUPPORT)
        return possible_performances.sort_by { |performance| performance.assists }.last
      end
    end
  end
end
