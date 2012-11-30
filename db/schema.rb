# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121130180749) do

  create_table "bit_files", :force => true do |t|
    t.integer  "directory_id"
    t.string   "md5sum"
    t.string   "name"
    t.string   "dx_name"
    t.string   "content_type"
    t.boolean  "dx_ingested"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "bit_files", ["content_type"], :name => "index_bit_files_on_content_type"
  add_index "bit_files", ["directory_id"], :name => "index_bit_files_on_directory_id"
  add_index "bit_files", ["dx_name"], :name => "index_bit_files_on_dx_name"
  add_index "bit_files", ["name"], :name => "index_bit_files_on_name"

  create_table "directories", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "parent_id"
  end

  add_index "directories", ["parent_id"], :name => "index_directories_on_parent_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

end
