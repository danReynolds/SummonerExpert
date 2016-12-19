RIOT_API = YAML.load_file(
  "#{Rails.root.to_s}/config/riot_api.yml"
).with_indifferent_access

CHAMPION_GG_API = YAML.load_file(
  "#{Rails.root.to_s}/config/champion_gg_api.yml"
).with_indifferent_access
