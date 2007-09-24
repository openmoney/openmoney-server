class EventAddResult < ActiveRecord::Migration
  def self.up
    add_column :events, :result, :text
  end

  def self.down
    remove_column :events, :result
  end
end
