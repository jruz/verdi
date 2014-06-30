require 'rubygems'
require 'mechanize'
require 'httparty'
require 'unidecoder'
require 'colorize'

def get_original_name(movie_url)
  agent = Mechanize.new
  agent.get movie_url
  items = agent.page.search('ul.listapeli span')
  return items.first.text
end

def name_cleaner(original_name)
  return URI::encode(original_name)
end

def get_id_from_imdb(original_name)
  clean_name  = name_cleaner(original_name)
  agent = Mechanize.new
  agent.get "http://www.imdb.com/find?q=#{clean_name}&s=tt&ttype=ft&exact=true"
  items = agent.page.search('td.result_text a')
  return items.first.attributes['href'].value.gsub('/title/','').gsub('/?ref_=fn_ft_tt_1','')
end

def get_data_from_name(original_name)
  clean_name  = name_cleaner(original_name)
  response    = HTTParty.get "http://www.omdbapi.com/?t=#{clean_name}"
  parsed      = JSON.parse(response)
  data        = { rating: parsed['imdbRating'], year: parsed['Year'] }
  return data
end

def get_data_from_id(movie_id)
  response    = HTTParty.get "http://www.omdbapi.com/?i=#{movie_id}"
  parsed      = JSON.parse(response)
  data        = { rating: parsed['imdbRating'], year: parsed['Year'] }
  return data
end

agent = Mechanize.new
agent.get 'http://www.cines-verdi.com/barcelona/cartelera/'
items = agent.page.search('.whitetitulo')

items.each do |item|
  movie_url     = item.attributes['href'].value
  spanish_name  = item.text
  original_name = get_original_name(movie_url)
  data          = get_data_from_name(original_name)
  if data[:rating].nil?
    movie_id  = get_id_from_imdb(original_name)
    data      = get_data_from_id(movie_id)
  end
  result = "#{spanish_name} | #{data[:year]} | #{data[:rating]}"
  result = result.colorize(:yellow) if data[:rating].to_f >= 7.5
  puts result
end
