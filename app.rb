require 'csv'
require 'pathname'
require 'pry'
require 'sinatra'
require 'sinatra/json'
require 'sinatra/reloader'

get '/BabyNames/:year' do |year|
  file = Pathname.new(__dir__).join('data', "yob#{year}.txt")
  raise Sinatra::NotFound unless file.exist?

  most_popular_mail_name, most_popular_female_name, least_popular_male_name, least_popular_female_name = nil

  CSV.foreach(file, headers: %w(name sex count)) do |row|
    Pry::ColorPrinter.pp row
  end

  json(
    most_popular_mail_name: most_popular_mail_name,
    most_popular_female_name: most_popular_female_name,
    least_popular_male_name: least_popular_male_name,
    least_popular_female_name: least_popular_female_name,
  )
end

not_found do
  json error: 'no data'
end
