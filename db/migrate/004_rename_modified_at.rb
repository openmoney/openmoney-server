class RenameModifiedAt < ActiveRecord::Migration
  def self.up
    rename_column :links, :modified_at, :updated_at
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
