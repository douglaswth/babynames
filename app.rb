#!/usr/bin/env ruby

require 'csv'
require 'ostruct'
require 'pathname'
require 'sinatra'
require 'sinatra/json'
require 'sinatra/reloader'

class BabyName < OpenStruct
  def initialize(row)
    super(name: row[:name], sex: row[:sex], count: row[:count].to_i, letter: row[:name]&.slice(0)&.upcase)
  end

  def more_popular(baby)
    !baby || count > baby.count ? self : baby
  end

  def less_popular(baby)
    !baby || count < baby.count ? self : baby
  end

  def least_popular(babies_by_letter)
    baby = babies_by_letter[letter]
    if baby == self
      baby, ordinal = nil, letter.ord
      until baby
        ordinal += 1
        ordinal = 'A'.ord if ordinal > 'Z'.ord
        break if ordinal == letter.ord
        baby = babies_by_letter[ordinal.chr]
      end
    end
    baby
  end
end

get '/BabyNames/:year' do |year|
  file = Pathname.new(__dir__).join('data', "yob#{year}.txt")
  raise Sinatra::NotFound unless file.exist?

  most_popular_male, most_popular_female = nil
  least_popular_male_by_letter, least_popular_female_by_letter = {}, {}

  CSV.foreach(file, headers: %i(name sex count)) do |row|
    baby = BabyName.new(row)
    case baby.sex
    when 'M'
      most_popular_male = baby.more_popular(most_popular_male)
      least_popular_male_by_letter[baby.letter] = baby.less_popular(least_popular_male_by_letter[baby.letter])
    when 'F'
      most_popular_female = baby.more_popular(most_popular_female)
      least_popular_female_by_letter[baby.letter] = baby.less_popular(least_popular_female_by_letter[baby.letter])
    end
  end

  least_popular_male = most_popular_male&.least_popular(least_popular_male_by_letter)
  least_popular_female = most_popular_female&.least_popular(least_popular_female_by_letter)

  json(
    most_popular_male_name: most_popular_male&.name,
    most_popular_female_name: most_popular_female&.name,
    least_popular_male_name: least_popular_male&.name,
    least_popular_female_name: least_popular_female&.name,
  )
end

not_found do
  json error: 'no data'
end

error do
  json error: env['sinatra.error']
end
