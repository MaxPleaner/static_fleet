class SavedScript < ActiveRecord::Base
  def self.migrate(cmd=:up)
    Migrations.migrate(cmd)
  end
  class Migrations < ActiveRecord::Migration[4.2]
    def up
      create_table :saved_scripts do |t|
        t.string :name
        t.string :category
        t.text :content
        t.timestamps null: false
      end
    end
    def down
      drop_table :todos
    end
  end
end
