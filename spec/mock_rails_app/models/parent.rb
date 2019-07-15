class Parent < ApplicationRecord
  has_many :children

  def favorite_star_wars_character
    Faker::Movies::StarWars.character
  end
end
