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

ActiveRecord::Schema.define(version: 20160908072903) do

  create_table "answers", force: :cascade do |t|
    t.integer  "question_id", limit: 4,        null: false
    t.text     "body",        limit: 16777215
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.datetime "deleted_at"
  end

  add_index "answers", ["deleted_at"], name: "index_answers_on_deleted_at", using: :btree
  add_index "answers", ["question_id"], name: "index_answers_on_question_id", using: :btree

  create_table "articles", force: :cascade do |t|
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.datetime "deleted_at"
    t.boolean  "hidden",                      default: false
    t.integer  "post_issue_id", limit: 4,                     null: false
    t.string   "active",        limit: 255,   default: "on"
    t.integer  "source_id",     limit: 4,                     null: false
    t.string   "source_type",   limit: 255,                   null: false
    t.text     "body",          limit: 65535
  end

  add_index "articles", ["deleted_at"], name: "index_articles_on_deleted_at", using: :btree
  add_index "articles", ["post_issue_id", "source_id", "source_type", "deleted_at"], name: "index_article_on_unique_link_source", unique: true, using: :btree
  add_index "articles", ["source_type", "source_id"], name: "index_articles_on_source_type_and_source_id", using: :btree

  create_table "campaigned_issues", force: :cascade do |t|
    t.integer  "campaign_id", limit: 4, null: false
    t.integer  "issue_id",    limit: 4, null: false
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  add_index "campaigned_issues", ["campaign_id", "issue_id"], name: "index_campaigned_issues_on_campaign_id_and_issue_id", unique: true, using: :btree
  add_index "campaigned_issues", ["campaign_id"], name: "index_campaigned_issues_on_campaign_id", using: :btree
  add_index "campaigned_issues", ["issue_id"], name: "index_campaigned_issues_on_issue_id", using: :btree

  create_table "campaigns", force: :cascade do |t|
    t.integer  "user_id",    limit: 4,                    null: false
    t.string   "title",      limit: 255,                  null: false
    t.string   "slug",       limit: 255,                  null: false
    t.text     "body",       limit: 65535
    t.string   "logo",       limit: 255
    t.string   "cover",      limit: 255
    t.datetime "deleted_at"
    t.string   "active",     limit: 255,   default: "on"
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
  end

  add_index "campaigns", ["slug", "active"], name: "index_campaigns_on_slug_and_active", unique: true, using: :btree
  add_index "campaigns", ["title", "active"], name: "index_campaigns_on_title_and_active", unique: true, using: :btree

  create_table "comments", force: :cascade do |t|
    t.integer  "user_id",       limit: 4,                    null: false
    t.integer  "post_id",       limit: 4,                    null: false
    t.text     "body",          limit: 16777215
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.string   "choice",        limit: 255
    t.datetime "deleted_at"
    t.integer  "upvotes_count", limit: 4,        default: 0
  end

  add_index "comments", ["deleted_at"], name: "index_comments_on_deleted_at", using: :btree
  add_index "comments", ["post_id"], name: "index_comments_on_post_id", using: :btree
  add_index "comments", ["user_id"], name: "index_comments_on_user_id", using: :btree

  create_table "discussions", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.text     "body",       limit: 16777215
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.datetime "deleted_at"
  end

  add_index "discussions", ["deleted_at"], name: "index_discussions_on_deleted_at", using: :btree

  create_table "featured_campaigns", force: :cascade do |t|
    t.string   "url",          limit: 255
    t.string   "image",        limit: 255
    t.string   "mobile_image", limit: 255
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.string   "title",        limit: 255
    t.text     "body",         limit: 65535
  end

  create_table "featured_issues", force: :cascade do |t|
    t.string   "title",         limit: 255
    t.string   "slug",          limit: 255
    t.string   "image",         limit: 255
    t.string   "mobile_image",  limit: 255
    t.string   "talk_title",    limit: 255
    t.integer  "talk_id",       limit: 4
    t.string   "article_title", limit: 255
    t.integer  "article_id",    limit: 4
    t.string   "opinion_title", limit: 255
    t.integer  "opinion_id",    limit: 4
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.text     "body",          limit: 65535
  end

  create_table "file_sources", force: :cascade do |t|
    t.string   "name",       limit: 255, null: false
    t.string   "attachment", limit: 255, null: false
    t.string   "file_type",  limit: 255, null: false
    t.integer  "file_size",  limit: 4,   null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "issues", force: :cascade do |t|
    t.string   "title",           limit: 255
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.text     "body",            limit: 16777215
    t.string   "logo",            limit: 255
    t.integer  "watches_count",   limit: 4,        default: 0
    t.string   "slug",            limit: 255
    t.integer  "posts_count",     limit: 4,        default: 0
    t.datetime "deleted_at"
    t.string   "active",          limit: 255,      default: "on"
    t.boolean  "basic",                            default: false
    t.string   "group_slug",      limit: 255
    t.string   "telegram_link",   limit: 255
    t.datetime "last_touched_at"
    t.string   "category_slug",   limit: 255
    t.integer  "members_count",   limit: 4,        default: 0
  end

  add_index "issues", ["deleted_at"], name: "index_issues_on_deleted_at", using: :btree
  add_index "issues", ["group_slug", "slug", "active"], name: "index_issues_on_group_slug_and_slug_and_active", unique: true, using: :btree
  add_index "issues", ["group_slug", "title", "active"], name: "index_issues_on_group_slug_and_title_and_active", unique: true, using: :btree

  create_table "likes", force: :cascade do |t|
    t.integer  "user_id",    limit: 4, null: false
    t.integer  "post_id",    limit: 4, null: false
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "likes", ["post_id"], name: "index_likes_on_post_id", using: :btree
  add_index "likes", ["user_id", "post_id"], name: "index_likes_on_user_id_and_post_id", unique: true, using: :btree
  add_index "likes", ["user_id"], name: "index_likes_on_user_id", using: :btree

  create_table "link_sources", force: :cascade do |t|
    t.string   "title",           limit: 255
    t.text     "body",            limit: 16777215
    t.text     "metadata",        limit: 16777215
    t.string   "image",           limit: 255
    t.string   "page_type",       limit: 255
    t.string   "url",             limit: 700
    t.string   "crawling_status", limit: 255,                  null: false
    t.datetime "crawled_at"
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.string   "site_name",       limit: 255
    t.integer  "image_height",    limit: 4,        default: 0
    t.integer  "image_width",     limit: 4,        default: 0
  end

  add_index "link_sources", ["url"], name: "index_link_sources_on_url", unique: true, using: :btree

  create_table "makers", force: :cascade do |t|
    t.integer  "user_id",    limit: 4, null: false
    t.integer  "issue_id",   limit: 4, null: false
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "makers", ["issue_id"], name: "index_makers_on_issue_id", using: :btree
  add_index "makers", ["user_id", "issue_id"], name: "index_makers_on_user_id_and_issue_id", unique: true, using: :btree
  add_index "makers", ["user_id"], name: "index_makers_on_user_id", using: :btree

  create_table "members", force: :cascade do |t|
    t.integer  "issue_id",   limit: 4, null: false
    t.integer  "user_id",    limit: 4, null: false
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "members", ["issue_id"], name: "index_members_on_issue_id", using: :btree
  add_index "members", ["user_id", "issue_id"], name: "index_members_on_user_id_and_issue_id", unique: true, using: :btree
  add_index "members", ["user_id"], name: "index_members_on_user_id", using: :btree

  create_table "mentions", force: :cascade do |t|
    t.integer  "user_id",          limit: 4,   null: false
    t.integer  "mentionable_id",   limit: 4,   null: false
    t.string   "mentionable_type", limit: 255
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "mentions", ["mentionable_type", "mentionable_id"], name: "index_mentions_on_mentionable_type_and_mentionable_id", using: :btree
  add_index "mentions", ["user_id", "mentionable_id", "mentionable_type"], name: "uniq_user_mention", unique: true, using: :btree
  add_index "mentions", ["user_id"], name: "index_mentions_on_user_id", using: :btree

  create_table "messages", force: :cascade do |t|
    t.integer  "user_id",         limit: 4,   null: false
    t.integer  "messagable_id",   limit: 4,   null: false
    t.string   "messagable_type", limit: 255
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "messages", ["messagable_type", "messagable_id"], name: "index_messages_on_messagable_type_and_messagable_id", using: :btree
  add_index "messages", ["user_id"], name: "index_messages_on_user_id", using: :btree

  create_table "notes", force: :cascade do |t|
    t.text     "body",          limit: 65535
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "post_issue_id", limit: 4,     null: false
  end

  create_table "opinions", force: :cascade do |t|
    t.string   "title",         limit: 255
    t.text     "body",          limit: 16777215
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.datetime "deleted_at"
    t.integer  "post_issue_id", limit: 4,        null: false
  end

  add_index "opinions", ["deleted_at"], name: "index_opinions_on_deleted_at", using: :btree

  create_table "parti_sso_client_api_keys", force: :cascade do |t|
    t.integer  "user_id",           limit: 4,                   null: false
    t.string   "digest",            limit: 255
    t.string   "client",            limit: 255
    t.integer  "authentication_id", limit: 4,                   null: false
    t.datetime "expires_at",                                    null: false
    t.datetime "last_access_at",                                null: false
    t.boolean  "is_locked",                     default: false, null: false
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
  end

  add_index "parti_sso_client_api_keys", ["client"], name: "index_parti_sso_client_api_keys_on_client", using: :btree
  add_index "parti_sso_client_api_keys", ["user_id", "client"], name: "index_parti_sso_client_api_keys_on_user_id_and_client", unique: true, using: :btree

  create_table "posts", force: :cascade do |t|
    t.integer  "issue_id",                          limit: 4,               null: false
    t.integer  "postable_id",                       limit: 4,               null: false
    t.string   "postable_type",                     limit: 255
    t.integer  "user_id",                           limit: 4,               null: false
    t.datetime "created_at",                                                null: false
    t.datetime "updated_at",                                                null: false
    t.integer  "likes_count",                       limit: 4,   default: 0
    t.integer  "comments_count",                    limit: 4,   default: 0
    t.integer  "votes_count",                       limit: 4,   default: 0
    t.datetime "deleted_at"
    t.string   "social_card",                       limit: 255
    t.integer  "latest_comments_count",             limit: 4,   default: 0
    t.string   "latest_comments_counted_datestamp", limit: 255
    t.datetime "last_commented_at"
    t.datetime "last_touched_at"
    t.integer  "upvotes_count",                     limit: 4,   default: 0
  end

  add_index "posts", ["deleted_at"], name: "index_posts_on_deleted_at", using: :btree
  add_index "posts", ["issue_id"], name: "index_posts_on_issue_id", using: :btree
  add_index "posts", ["postable_type", "postable_id"], name: "index_posts_on_postable_type_and_postable_id", using: :btree
  add_index "posts", ["user_id"], name: "index_posts_on_user_id", using: :btree

  create_table "proposals", force: :cascade do |t|
    t.integer  "discussion_id", limit: 4,        null: false
    t.text     "body",          limit: 16777215
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.datetime "deleted_at"
  end

  add_index "proposals", ["deleted_at"], name: "index_proposals_on_deleted_at", using: :btree
  add_index "proposals", ["discussion_id"], name: "index_proposals_on_discussion_id", using: :btree

  create_table "questions", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.text     "body",       limit: 16777215
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "redactor2_assets", force: :cascade do |t|
    t.integer  "user_id",           limit: 4
    t.string   "data_file_name",    limit: 255
    t.string   "data_content_type", limit: 255
    t.integer  "data_file_size",    limit: 4
    t.integer  "assetable_id",      limit: 4
    t.string   "assetable_type",    limit: 30
    t.string   "type",              limit: 30
    t.integer  "width",             limit: 4
    t.integer  "height",            limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "redactor2_assets", ["assetable_type", "assetable_id"], name: "idx_redactor2_assetable", using: :btree
  add_index "redactor2_assets", ["assetable_type", "type", "assetable_id"], name: "idx_redactor2_assetable_type", using: :btree

  create_table "relateds", force: :cascade do |t|
    t.integer  "issue_id",   limit: 4, null: false
    t.integer  "target_id",  limit: 4, null: false
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "relateds", ["issue_id", "target_id"], name: "index_relateds_on_issue_id_and_target_id", unique: true, using: :btree
  add_index "relateds", ["issue_id"], name: "index_relateds_on_issue_id", using: :btree
  add_index "relateds", ["target_id"], name: "index_relateds_on_target_id", using: :btree

  create_table "searches", force: :cascade do |t|
    t.integer  "searchable_id",   limit: 4,        null: false
    t.string   "searchable_type", limit: 255
    t.text     "content",         limit: 16777215
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
  end

  add_index "searches", ["searchable_type", "searchable_id"], name: "index_searches_on_searchable_type_and_searchable_id", using: :btree

  create_table "sections", force: :cascade do |t|
    t.string   "name",       limit: 255,                 null: false
    t.integer  "issue_id",   limit: 4,                   null: false
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.boolean  "initial",                default: false
  end

  add_index "sections", ["issue_id"], name: "index_sections_on_issue_id", using: :btree
  add_index "sections", ["name"], name: "index_sections_on_name", using: :btree

  create_table "taggings", force: :cascade do |t|
    t.integer  "tag_id",        limit: 4
    t.integer  "taggable_id",   limit: 4
    t.string   "taggable_type", limit: 255
    t.integer  "tagger_id",     limit: 4
    t.string   "tagger_type",   limit: 255
    t.string   "context",       limit: 128
    t.datetime "created_at"
  end

  add_index "taggings", ["context"], name: "index_taggings_on_context", using: :btree
  add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true, using: :btree
  add_index "taggings", ["tag_id"], name: "index_taggings_on_tag_id", using: :btree
  add_index "taggings", ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context", using: :btree
  add_index "taggings", ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy", using: :btree
  add_index "taggings", ["taggable_id"], name: "index_taggings_on_taggable_id", using: :btree
  add_index "taggings", ["taggable_type"], name: "index_taggings_on_taggable_type", using: :btree
  add_index "taggings", ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type", using: :btree
  add_index "taggings", ["tagger_id"], name: "index_taggings_on_tagger_id", using: :btree

  create_table "tags", force: :cascade do |t|
    t.string  "name",           limit: 255
    t.integer "taggings_count", limit: 4,   default: 0
  end

  add_index "tags", ["name"], name: "index_tags_on_name", unique: true, using: :btree

  create_table "talks", force: :cascade do |t|
    t.string   "title",         limit: 255
    t.datetime "deleted_at"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.text     "body",          limit: 65535
    t.integer  "post_issue_id", limit: 4,     null: false
    t.integer  "section_id",    limit: 4,     null: false
  end

  add_index "talks", ["section_id"], name: "index_talks_on_section_id", using: :btree

  create_table "upvotes", force: :cascade do |t|
    t.integer  "user_id",        limit: 4,   null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "upvotable_id",   limit: 4,   null: false
    t.string   "upvotable_type", limit: 255, null: false
    t.integer  "issue_id",       limit: 4
  end

  add_index "upvotes", ["issue_id"], name: "index_upvotes_on_issue_id", using: :btree
  add_index "upvotes", ["user_id", "upvotable_id", "upvotable_type"], name: "index_upvotes_on_user_id_and_upvotable_id_and_upvotable_type", unique: true, using: :btree
  add_index "upvotes", ["user_id"], name: "index_upvotes_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255
    t.string   "encrypted_password",     limit: 255
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,   default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.string   "confirmation_token",     limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",      limit: 255
    t.string   "nickname",               limit: 255
    t.string   "image",                  limit: 255
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.string   "provider",               limit: 255
    t.string   "uid",                    limit: 255
    t.datetime "deleted_at"
    t.integer  "unread_messages_count",  limit: 4,   default: 0
    t.string   "active",                 limit: 255, default: "on"
    t.boolean  "enable_mailing",                     default: true
    t.boolean  "root_as_dashboard",                  default: false
  end

  add_index "users", ["confirmation_token", "active"], name: "index_users_on_confirmation_token_and_active", unique: true, using: :btree
  add_index "users", ["deleted_at"], name: "index_users_on_deleted_at", using: :btree
  add_index "users", ["nickname", "active"], name: "index_users_on_nickname_and_active", unique: true, using: :btree
  add_index "users", ["provider", "uid", "active"], name: "index_users_on_provider_and_uid_and_active", unique: true, using: :btree
  add_index "users", ["reset_password_token", "active"], name: "index_users_on_reset_password_token_and_active", unique: true, using: :btree

  create_table "votes", force: :cascade do |t|
    t.integer  "user_id",    limit: 4,   null: false
    t.string   "choice",     limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "post_id",    limit: 4,   null: false
  end

  add_index "votes", ["post_id", "user_id"], name: "index_votes_on_post_id_and_user_id", unique: true, using: :btree
  add_index "votes", ["user_id"], name: "index_votes_on_user_id", using: :btree

  create_table "watches", force: :cascade do |t|
    t.integer  "user_id",    limit: 4, null: false
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.integer  "issue_id",   limit: 4, null: false
  end

  add_index "watches", ["issue_id"], name: "index_watches_on_issue_id", using: :btree
  add_index "watches", ["user_id", "issue_id"], name: "index_watches_on_user_id_and_issue_id", unique: true, using: :btree
  add_index "watches", ["user_id"], name: "index_watches_on_user_id", using: :btree

  create_table "wiki_histories", force: :cascade do |t|
    t.integer  "user_id",    limit: 4,     null: false
    t.integer  "wiki_id",    limit: 4,     null: false
    t.text     "body",       limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "wiki_histories", ["user_id"], name: "index_wiki_histories_on_user_id", using: :btree
  add_index "wiki_histories", ["wiki_id"], name: "index_wiki_histories_on_wiki_id", using: :btree

  create_table "wikis", force: :cascade do |t|
    t.integer  "issue_id",   limit: 4
    t.text     "body",       limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "wikis", ["issue_id"], name: "index_wikis_on_issue_id", using: :btree

end
