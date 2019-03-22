class Initial < ActiveRecord::Migration[5.1]
  def self.up
    create_table :instances do |t|
      t.string :name
      t.string :feature
      t.string :description
      t.string :assigned_to
      t.datetime :updated
    end
  end

  def self.down
    drop_table :instances
  end
end
