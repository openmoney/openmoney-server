class CreateLinks < ActiveRecord::Migration
  def self.up
    create_table :links do |t|
      t.column :entity_id, :integer
      t.column :omrl, :string
      t.column :link_type, :string
      t.column :signature, :text
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :links
  end
end
