class RenameLinkSignatureColumn < ActiveRecord::Migration
  def self.up
    rename_column :links, :signature, :specification
  end

  def self.down
    rename_column :links, :specification, :signature
  end
end
