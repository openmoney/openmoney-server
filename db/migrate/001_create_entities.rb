class CreateEntities < ActiveRecord::Migration
  def self.up
    create_table :entities do |t|
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :entity_type, :string
      t.column :access_control, :text
      t.column :specification, :text
    end
    root = Entity.new(:entity_type => 'context')
    root.set_credential('steward','password')
    root.save
  end

  def self.down
    drop_table :entities
  end
end
