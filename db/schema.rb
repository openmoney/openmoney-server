# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 4) do

  create_table "averages", :force => true do |t|
    t.float   "average_declared"
    t.float   "average_accepted"
    t.float   "volume"
    t.integer "count_declared"
    t.integer "count_accepted"
  end

  create_table "balances", :force => true do |t|
    t.float   "balance"
    t.float   "volume"
    t.integer "count"
  end

  create_table "entities", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "entity_type"
    t.text     "access_control"
    t.text     "specification"
  end

  create_table "events", :force => true do |t|
    t.datetime "created_at"
    t.string   "event_type"
    t.text     "specification"
    t.text     "result"
    t.string   "state"
  end

  create_table "links", :force => true do |t|
    t.integer  "entity_id"
    t.string   "omrl"
    t.string   "link_type"
    t.text     "specification"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "summary_entries", :force => true do |t|
    t.string   "currency_omrl"
    t.string   "entity_omrl"
    t.integer  "summary_id"
    t.string   "summary_type"
    t.datetime "updated_at"
  end

end
