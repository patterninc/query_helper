require 'bundler/setup'
require 'query_helper'
require 'sqlite3'
require 'active_record'
require 'faker'
require 'byebug'
require 'fixtures/models'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    @filter = {
      "id" => {
        "gte" => 20,
        "lt" => 40
      }
    }
    @per_page = Faker::Number.between(5,15)
    @page = Faker::Number.between(2,5)
    @url_params = {
      parent_id: 1,
      random_param: true,
      per_page: @per_page.to_s,
      page: @page.to_s,
      filter: @filter,
      sort: "name:desc",
      include: "parent"
    }
  end

  # Set up a database that resides in RAM
  ActiveRecord::Base.establish_connection(
    adapter: "sqlite3",
    database: ':memory:'
  )

  # Set up database tables and columns
  ActiveRecord::Schema.define do
    create_table :parents, force: true do |t|
      t.string :name
      t.integer :age
    end
    create_table :children, force: true do |t|
      t.string :name
      t.references :parent
      t.integer :age
    end
  end

  # Load data into databases
  (0..99).each do
    parent = Parent.create(name: Faker::Name.name, age: Faker::Number.between(25, 55))
    (0..Faker::Number.between(1, 5)).each do
      Child.create(name: Faker::Name.name, parent: parent, age: Faker::Number.between(1, 25))
    end
  end
end
