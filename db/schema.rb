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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20130729213328) do

  create_table "rpm_dependencies", force: true do |t|
    t.string   "dependency"
    t.string   "version"
    t.string   "neededby"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rpm_dependencies", ["dependency", "version", "neededby"], name: "index_rpm_dependencies_on_dependency_and_version_and_neededby", using: :btree

  create_table "rpm_packages", force: true do |t|
    t.string   "package_key", null: false
    t.string   "dist"
    t.string   "rpp"
    t.string   "rpm"
    t.string   "version"
    t.string   "arch"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rpm_packages", ["package_key"], name: "index_rpm_packages_on_package_key", unique: true, using: :btree

  create_table "rpm_provides", force: true do |t|
    t.string   "provides"
    t.string   "providedby"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rpm_provides", ["provides", "providedby"], name: "index_rpm_provides_on_provides_and_providedby", using: :btree

end
