class CreateEntities < ActiveRecord::Migration
  def self.up
    create_table :entities do |t|
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :entity_type, :string
      t.column :access_control, :text
      t.column :specification, :text
    end
  end

  def self.down
    drop_table :entities
  end
end
