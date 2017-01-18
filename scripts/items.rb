require 'net/http'
require 'json'
require 'pry'

items = JSON.parse(File.read('items.json'))['data']
f = File.new('items-output.json', 'w+')
f.write(
  items.reject { |_, item| item['name'].nil? || item['name'].include?('(') }.map do |_, item|
    {
      value: item['name'],
      synonyms: [item['name']]
    }
  end.sort_by do |item_data|
    item_data[:value].length
  end.reverse.first(100).to_json
)
