class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.column :created_at, :datetime
      t.column :event_type, :string
      t.column :specification, :text
      t.column :result, :text
      t.column :state, :string
    end
  end

  def self.down
    drop_table :events
  end
end
