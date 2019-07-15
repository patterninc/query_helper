require_relative('models/child')
require_relative('models/parent')

module MockRailsApp
  extend self
    def setup
      QueryHelper.active_record_adapter = "sqlite3" # Use sqlite3 in memory for test suites
      create_tables()
      populate_tables()
    end

    def create_tables
      # Set up a database that resides in RAM
      ActiveRecord::Base.establish_connection(
        adapter: QueryHelper.active_record_adapter,
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
    end

    def populate_tables
      # Load data into databases
      (0..99).each do
        parent = Parent.create(name: Faker::Name.name, age: Faker::Number.between(25, 55))
        (0..Faker::Number.between(1, 5)).each do
          Child.create(name: Faker::Name.name, parent: parent, age: Faker::Number.between(1, 25))
        end
      end
    end
end
