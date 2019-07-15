# class Post
#   extend ActiveModel::Naming
#   include ActiveModel::Conversion
#   attr_accessor :id
#
#   def initialize(attributes={})
#     self.id = attributes
#   end
#
#   def persisted?
#     true
#   end
# end
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
class Parent < ApplicationRecord
  has_many :children

  def favorite_star_wars_character
    Faker::Movies::StarWars.character
  end
end
class Child < ApplicationRecord
  belongs_to :parent
end
