require 'net/http'
require 'json'
require 'pry'

champions = JSON.parse(File.read('champions.txt'))[:data]
f = File.new('champions-output.txt', 'w+')
f.write(
  champions.map do |champion, data|
    "#{champion},#{data[:name]},#{data[:title]}"
  end
)
