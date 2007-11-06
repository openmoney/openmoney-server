class CreateSummaryEntries < ActiveRecord::Migration
  def self.up
    create_table :summary_entries do |t|
      t.string :currency_omrl
      t.string :entity_omrl
      t.integer :summary_id
      t.string :summary_type
      t.datetime :updated_at 
    end
    create_table :balances do |t|
      t.float :balance
      t.float :volume
      t.integer :count
    end
    create_table :averages do |t|
      t.float :average_declared
      t.float :average_accepted
      t.float :volume
      t.integer :count_declared
      t.integer :count_accepted
    end
  end

  def self.down
    drop_table :summary_entries
    drop_table :balances
    drop_table :averages
  end
end
