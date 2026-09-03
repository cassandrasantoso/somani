# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_03_033923) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vector"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "adventures", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "goal_dismissed_at"
    t.datetime "goal_reached_at"
    t.bigint "scene_id"
    t.string "status"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "upload_id", null: false
    t.index ["scene_id"], name: "index_adventures_on_scene_id"
    t.index ["upload_id"], name: "index_adventures_on_upload_id"
  end

  create_table "characters", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.text "persona"
    t.datetime "updated_at", null: false
    t.string "voice"
  end

  create_table "feedbacks", force: :cascade do |t|
    t.text "assessment"
    t.string "coherence"
    t.text "coherence_note"
    t.jsonb "corrections", default: []
    t.datetime "created_at", null: false
    t.text "encouragement"
    t.string "level_estimate"
    t.bigint "message_id", null: false
    t.datetime "updated_at", null: false
    t.text "used_learned_words"
    t.index ["coherence"], name: "index_feedbacks_on_coherence"
    t.index ["message_id"], name: "index_feedbacks_on_message_id", unique: true
  end

  create_table "friendships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "followed_id", null: false
    t.bigint "follower_id", null: false
    t.datetime "updated_at", null: false
    t.index ["followed_id"], name: "index_friendships_on_followed_id"
    t.index ["follower_id", "followed_id"], name: "index_friendships_on_follower_id_and_followed_id", unique: true
    t.index ["follower_id"], name: "index_friendships_on_follower_id"
  end

  create_table "jlpt_entries", force: :cascade do |t|
    t.string "content"
    t.datetime "created_at", null: false
    t.string "entry_type"
    t.string "level"
    t.text "meaning"
    t.string "reading"
    t.datetime "updated_at", null: false
    t.index ["entry_type", "content"], name: "index_jlpt_entries_on_entry_type_and_content"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "adventure_id", null: false
    t.text "body"
    t.datetime "created_at", null: false
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["adventure_id"], name: "index_messages_on_adventure_id"
  end

  create_table "saved_words", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.text "explanation"
    t.bigint "jlpt_entry_id"
    t.datetime "last_reviewed_at"
    t.string "level"
    t.string "level_source"
    t.text "meaning"
    t.datetime "next_review_at"
    t.string "reading"
    t.string "surface"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["jlpt_entry_id"], name: "index_saved_words_on_jlpt_entry_id"
    t.index ["user_id", "surface"], name: "index_saved_words_on_user_id_and_surface", unique: true
    t.index ["user_id"], name: "index_saved_words_on_user_id"
  end

  create_table "scenes", force: :cascade do |t|
    t.bigint "character_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.vector "embedding", limit: 768
    t.string "level"
    t.string "setting"
    t.datetime "updated_at", null: false
    t.index ["character_id"], name: "index_scenes_on_character_id"
  end

  create_table "uploaded_words", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "saved_word_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "upload_id", null: false
    t.index ["saved_word_id"], name: "index_uploaded_words_on_saved_word_id"
    t.index ["upload_id", "saved_word_id"], name: "index_uploaded_words_on_upload_id_and_saved_word_id", unique: true
    t.index ["upload_id"], name: "index_uploaded_words_on_upload_id"
  end

  create_table "uploads", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "extracted_text"
    t.string "file_location"
    t.string "media_type"
    t.text "summary"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_uploads_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.boolean "reminder_enabled", default: false, null: false
    t.time "reminder_time"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "word_corrections", force: :cascade do |t|
    t.text "better", null: false
    t.datetime "created_at", null: false
    t.bigint "feedback_id", null: false
    t.string "kind", null: false
    t.bigint "saved_word_id"
    t.string "surface", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.text "why"
    t.text "wrote", null: false
    t.index ["feedback_id"], name: "index_word_corrections_on_feedback_id"
    t.index ["saved_word_id"], name: "index_word_corrections_on_saved_word_id"
    t.index ["surface", "kind"], name: "index_word_corrections_on_surface_and_kind"
    t.index ["user_id", "surface"], name: "index_word_corrections_on_user_id_and_surface"
    t.index ["user_id"], name: "index_word_corrections_on_user_id"
  end

  create_table "word_goals", force: :cascade do |t|
    t.bigint "adventure_id", null: false
    t.datetime "created_at", null: false
    t.bigint "saved_word_id", null: false
    t.integer "target", null: false
    t.datetime "updated_at", null: false
    t.index ["adventure_id", "saved_word_id"], name: "index_word_goals_on_adventure_id_and_saved_word_id", unique: true
    t.index ["adventure_id"], name: "index_word_goals_on_adventure_id"
    t.index ["saved_word_id"], name: "index_word_goals_on_saved_word_id"
  end

  create_table "word_usages", force: :cascade do |t|
    t.bigint "adventure_id", null: false
    t.datetime "created_at", null: false
    t.bigint "message_id", null: false
    t.bigint "saved_word_id", null: false
    t.string "status", default: "credited", null: false
    t.datetime "updated_at", null: false
    t.index ["adventure_id", "saved_word_id"], name: "index_word_usages_on_adventure_id_and_saved_word_id"
    t.index ["adventure_id"], name: "index_word_usages_on_adventure_id"
    t.index ["message_id", "saved_word_id"], name: "index_word_usages_on_message_id_and_saved_word_id", unique: true
    t.index ["message_id"], name: "index_word_usages_on_message_id"
    t.index ["saved_word_id"], name: "index_word_usages_on_saved_word_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "adventures", "scenes"
  add_foreign_key "adventures", "uploads"
  add_foreign_key "feedbacks", "messages"
  add_foreign_key "friendships", "users", column: "followed_id"
  add_foreign_key "friendships", "users", column: "follower_id"
  add_foreign_key "messages", "adventures"
  add_foreign_key "saved_words", "jlpt_entries"
  add_foreign_key "saved_words", "users"
  add_foreign_key "scenes", "characters"
  add_foreign_key "uploaded_words", "saved_words"
  add_foreign_key "uploaded_words", "uploads"
  add_foreign_key "uploads", "users"
  add_foreign_key "word_corrections", "feedbacks"
  add_foreign_key "word_corrections", "saved_words", on_delete: :nullify
  add_foreign_key "word_corrections", "users"
  add_foreign_key "word_goals", "adventures"
  add_foreign_key "word_goals", "saved_words"
  add_foreign_key "word_usages", "adventures"
  add_foreign_key "word_usages", "messages"
  add_foreign_key "word_usages", "saved_words"
end
