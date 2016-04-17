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

ActiveRecord::Schema.define(version: 20160417140937) do

  create_table "answers", force: :cascade do |t|
    t.integer  "question_id", null: false
    t.text     "body"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.datetime "deleted_at"
  end

  add_index "answers", ["deleted_at"], name: "index_answers_on_deleted_at"
  add_index "answers", ["question_id"], name: "index_answers_on_question_id"

  create_table "articles", force: :cascade do |t|
    t.string   "link",                           null: false
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.datetime "deleted_at"
    t.integer  "link_source_id",                 null: false
    t.boolean  "hidden",         default: false
    t.integer  "post_issue_id",                  null: false
    t.string   "active",         default: "on"
  end

  add_index "articles", ["post_issue_id", "link_source_id", "active"], name: "index_articles_on_unique_link_source", unique: true

  create_table "comments", force: :cascade do |t|
    t.integer  "user_id",                   null: false
    t.integer  "post_id",                   null: false
    t.text     "body"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.string   "choice"
    t.datetime "deleted_at"
    t.integer  "upvotes_count", default: 0
  end

  add_index "comments", ["deleted_at"], name: "index_comments_on_deleted_at"
  add_index "comments", ["post_id"], name: "index_comments_on_post_id"
  add_index "comments", ["user_id"], name: "index_comments_on_user_id"

  create_table "discussions", force: :cascade do |t|
    t.string   "title",      null: false
    t.text     "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
  end

  add_index "discussions", ["deleted_at"], name: "index_discussions_on_deleted_at"

  create_table "issues", force: :cascade do |t|
    t.string   "title",                        null: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.text     "body"
    t.string   "logo"
    t.string   "cover"
    t.integer  "watches_count", default: 0
    t.string   "slug",                         null: false
    t.integer  "posts_count",   default: 0
    t.datetime "deleted_at"
    t.string   "active",        default: "on"
  end

  add_index "issues", ["deleted_at"], name: "index_issues_on_deleted_at"
  add_index "issues", ["slug", "active"], name: "index_issues_on_slug_and_active", unique: true
  add_index "issues", ["title", "active"], name: "index_issues_on_title_and_active", unique: true

  create_table "likes", force: :cascade do |t|
    t.integer  "user_id",    null: false
    t.integer  "post_id",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "likes", ["post_id"], name: "index_likes_on_post_id"
  add_index "likes", ["user_id", "post_id"], name: "index_likes_on_user_id_and_post_id", unique: true
  add_index "likes", ["user_id"], name: "index_likes_on_user_id"

  create_table "link_sources", force: :cascade do |t|
    t.string   "title"
    t.text     "body"
    t.text     "metadata"
    t.string   "image"
    t.string   "page_type"
    t.string   "url"
    t.string   "crawling_status", default: "not_yet", null: false
    t.datetime "crawled_at"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "link_sources", ["url"], name: "index_link_sources_on_url", unique: true

  create_table "mentions", force: :cascade do |t|
    t.integer  "user_id",          null: false
    t.integer  "mentionable_id",   null: false
    t.string   "mentionable_type", null: false
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "mentions", ["mentionable_type", "mentionable_id"], name: "index_mentions_on_mentionable_type_and_mentionable_id"
  add_index "mentions", ["user_id", "mentionable_id", "mentionable_type"], name: "uniq_user_mention", unique: true
  add_index "mentions", ["user_id"], name: "index_mentions_on_user_id"

  create_table "messages", force: :cascade do |t|
    t.integer  "user_id",         null: false
    t.integer  "messagable_id",   null: false
    t.string   "messagable_type", null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "messages", ["messagable_type", "messagable_id"], name: "index_messages_on_messagable_type_and_messagable_id"
  add_index "messages", ["user_id"], name: "index_messages_on_user_id"

# Could not dump table "old_articles" because of following NoMethodError
#   undefined method `[]' for nil:NilClass

  create_table "old_users", force: :cascade do |t|
    t.string   "email",      null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "nickname",   null: false
  end

  add_index "old_users", ["email"], name: "index_old_users_on_email", unique: true
  add_index "old_users", ["nickname"], name: "index_old_users_on_nickname", unique: true

  create_table "opinions", force: :cascade do |t|
    t.string   "title",      null: false
    t.text     "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
  end

  add_index "opinions", ["deleted_at"], name: "index_opinions_on_deleted_at"

  create_table "parti_sso_client_api_keys", force: :cascade do |t|
    t.integer  "user_id",                           null: false
    t.string   "digest",                            null: false
    t.string   "client",                            null: false
    t.integer  "authentication_id",                 null: false
    t.datetime "expires_at",                        null: false
    t.datetime "last_access_at",                    null: false
    t.boolean  "is_locked",         default: false, null: false
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
  end

  add_index "parti_sso_client_api_keys", ["client"], name: "index_parti_sso_client_api_keys_on_client"
  add_index "parti_sso_client_api_keys", ["user_id", "client"], name: "index_parti_sso_client_api_keys_on_user_id_and_client", unique: true

  create_table "posts", force: :cascade do |t|
    t.integer  "issue_id",                          null: false
    t.integer  "postable_id",                       null: false
    t.string   "postable_type",                     null: false
    t.integer  "user_id",                           null: false
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.integer  "likes_count",           default: 0
    t.integer  "comments_count",        default: 0
    t.integer  "votes_count",           default: 0
    t.datetime "deleted_at"
    t.string   "social_card"
    t.integer  "latest_comments_count", default: 0
  end

  add_index "posts", ["deleted_at"], name: "index_posts_on_deleted_at"
  add_index "posts", ["issue_id"], name: "index_posts_on_issue_id"
  add_index "posts", ["postable_type", "postable_id"], name: "index_posts_on_postable_type_and_postable_id"
  add_index "posts", ["user_id"], name: "index_posts_on_user_id"

  create_table "proposals", force: :cascade do |t|
    t.integer  "discussion_id", null: false
    t.text     "body"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.datetime "deleted_at"
  end

  add_index "proposals", ["deleted_at"], name: "index_proposals_on_deleted_at"
  add_index "proposals", ["discussion_id"], name: "index_proposals_on_discussion_id"

  create_table "questions", force: :cascade do |t|
    t.string   "title",      null: false
    t.text     "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "redactor2_assets", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "data_file_name",               null: false
    t.string   "data_content_type"
    t.integer  "data_file_size"
    t.integer  "assetable_id"
    t.string   "assetable_type",    limit: 30
    t.string   "type",              limit: 30
    t.integer  "width"
    t.integer  "height"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "redactor2_assets", ["assetable_type", "assetable_id"], name: "idx_redactor2_assetable"
  add_index "redactor2_assets", ["assetable_type", "type", "assetable_id"], name: "idx_redactor2_assetable_type"

  create_table "redactor_assets", force: :cascade do |t|
    t.string   "data_file_name",               null: false
    t.string   "data_content_type"
    t.integer  "data_file_size"
    t.integer  "assetable_id"
    t.string   "assetable_type",    limit: 30
    t.string   "type",              limit: 30
    t.integer  "width"
    t.integer  "height"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "redactor_assets", ["assetable_type", "assetable_id"], name: "idx_redactor_assetable"
  add_index "redactor_assets", ["assetable_type", "type", "assetable_id"], name: "idx_redactor_assetable_type"

  create_table "relateds", force: :cascade do |t|
    t.integer  "issue_id",   null: false
    t.integer  "target_id",  null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "relateds", ["issue_id", "target_id"], name: "index_relateds_on_issue_id_and_target_id", unique: true
  add_index "relateds", ["issue_id"], name: "index_relateds_on_issue_id"
  add_index "relateds", ["target_id"], name: "index_relateds_on_target_id"

  create_table "searches", force: :cascade do |t|
    t.integer  "searchable_id",   null: false
    t.string   "searchable_type", null: false
    t.text     "content"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "searches", ["searchable_type", "searchable_id"], name: "index_searches_on_searchable_type_and_searchable_id"

  create_table "taggings", force: :cascade do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context",       limit: 128
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
  add_index "taggings", ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", force: :cascade do |t|
    t.string  "name"
    t.integer "taggings_count", default: 0
  end

  add_index "tags", ["name"], name: "index_tags_on_name", unique: true

  create_table "talks", force: :cascade do |t|
    t.string   "title",      null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "upvotes", force: :cascade do |t|
    t.integer  "user_id",    null: false
    t.integer  "comment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "upvotes", ["comment_id"], name: "index_upvotes_on_comment_id"
  add_index "upvotes", ["user_id", "comment_id"], name: "index_upvotes_on_user_id_and_comment_id", unique: true
  add_index "upvotes", ["user_id"], name: "index_upvotes_on_user_id"

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "",      null: false
    t.string   "encrypted_password",     default: "",      null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,       null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.string   "nickname",                                 null: false
    t.string   "image"
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.string   "provider",               default: "email", null: false
    t.string   "uid",                                      null: false
    t.datetime "deleted_at"
    t.integer  "unread_messages_count",  default: 0
    t.string   "active",                 default: "on"
  end

  add_index "users", ["confirmation_token", "active"], name: "index_users_on_confirmation_token_and_active", unique: true
  add_index "users", ["deleted_at"], name: "index_users_on_deleted_at"
  add_index "users", ["nickname", "active"], name: "index_users_on_nickname_and_active", unique: true
  add_index "users", ["provider", "uid", "active"], name: "index_users_on_provider_and_uid_and_active", unique: true
  add_index "users", ["reset_password_token", "active"], name: "index_users_on_reset_password_token_and_active", unique: true

  create_table "votes", force: :cascade do |t|
    t.integer  "user_id",    null: false
    t.string   "choice",     null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "post_id",    null: false
  end

  add_index "votes", ["post_id", "user_id"], name: "index_votes_on_post_id_and_user_id", unique: true
  add_index "votes", ["user_id"], name: "index_votes_on_user_id"

  create_table "watches", force: :cascade do |t|
    t.integer  "issue_id",   null: false
    t.integer  "user_id",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "watches", ["issue_id"], name: "index_watches_on_issue_id"
  add_index "watches", ["user_id", "issue_id"], name: "index_watches_on_user_id_and_issue_id", unique: true
  add_index "watches", ["user_id"], name: "index_watches_on_user_id"

end
