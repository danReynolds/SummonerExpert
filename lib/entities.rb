include ActionView::Helpers::DateHelper

class Entities
  relay_entities = [
    :summoner, :champion, :sort_type, :total_performances,
    :real_size, :requested_size, :filtered_size, :list_order, :filtered_position_offset,
    :summoners, :real_size_summoner_conjugation, :name, :champion2, :position_value,
    :winrate, :kills, :deaths, :assists, :count, :build, :lp, :rank, :queue, :hot_streak,
    :elo, :champions, :real_size_champion_conjugation, :spells, :real_size_combination_conjugation,
    :real_size_champion_conjugation, :stat, :level, :stat_name, :start_order, :max_order,
    :item_names, :position, :champ1_result, :champ2_result, :role1, :role2, :champion1, :champion2,
    :match_result, :unnamed_role, :named_role, :position_name, :win_rate, :ban_rate,
    :kda, :total_positions, :position_change, :description, :ability, :ability_cooldown, :lore,
    :tip, :item, :total_cost, :sell_cost, :title, :ability_position, :matchup_role, :patch, :metric
  ].each do |entity|
    define_singleton_method(entity) do |value|
      value.to_s
    end
  end

  class << self
    def role(role)
      if role.class == Array
        roles = role.map { |role| ChampionGGApi::ROLES[role.to_sym].try(:humanize) || role.humanize }.compact
        role.empty? ? '' : "across #{roles.sort.en.conjunction(article: false)}"
      else
        ChampionGGApi::ROLES[role.to_sym].try(:humanize) || role.humanize
      end
    end

    def starting_time(time)
      "from #{time.strftime("%a %b %e %R")}"
    end

    def ending_time(time)
      "to #{time.strftime("%a %b %e %R")}"
    end

    def summoners(summoners)
      return '' unless summoners.present?
      summoners.en.conjunction(article: false)
    end

    def list_position(position)
      position === 1.en.ordinate ? '' : position
    end

    def random_response(values)
      values.sample
    end
  end
end
