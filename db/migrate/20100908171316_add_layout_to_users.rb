class AddLayoutToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :layout, :string
  end

  def self.down
    remove_column :users, :layout
  end
end
