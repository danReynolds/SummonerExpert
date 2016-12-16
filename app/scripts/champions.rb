require 'net/http'
require 'json'
require 'pry'

champions = JSON.parse(File.read('champions.json'))['data']
f = File.new('champions-output.json', 'w+')
f.write(
  champions.map do |_, champion|
    {
      value: champion['name'],
      synonyms: [champion['name'], champion['title']]
    }
  end.sort_by do |champion_data|
    champion_data[:value].length
  end.reverse.first(100).to_json
)
