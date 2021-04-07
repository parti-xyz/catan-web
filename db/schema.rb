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

ActiveRecord::Schema.define(version: 2021_04_07_230725) do

  create_table "active_issue_stats", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "issue_id", null: false
    t.date "stat_at", null: false
    t.integer "new_posts_count", default: 0
    t.integer "new_comments_count", default: 0
    t.integer "new_members_count", default: 0
    t.index ["issue_id"], name: "index_active_issue_stats_on_issue_id"
    t.index ["stat_at"], name: "index_active_issue_stats_on_stat_at"
  end

  create_table "announcements", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "audiences_count", default: 0, null: false
    t.integer "noticed_audiences_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "stopped_at"
  end

  create_table "answers", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "question_id", null: false
    t.text "body", limit: 16777215
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_answers_on_deleted_at"
    t.index ["question_id"], name: "index_answers_on_question_id"
  end

  create_table "articles", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.boolean "hidden", default: false
    t.integer "post_issue_id", null: false
    t.string "active", default: "on"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.text "body"
    t.index ["deleted_at"], name: "index_articles_on_deleted_at"
    t.index ["source_type", "source_id"], name: "index_articles_on_source_type_and_source_id"
  end

  create_table "audiences", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.bigint "announcement_id", null: false
    t.bigint "member_id", null: false
    t.datetime "noticed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["announcement_id", "member_id"], name: "index_audiences_on_announcement_id_and_member_id", unique: true
    t.index ["announcement_id"], name: "index_audiences_on_announcement_id"
    t.index ["member_id"], name: "index_audiences_on_member_id"
  end

  create_table "beholders", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "post_id", null: false
    t.integer "deprecated_member_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["deprecated_member_id"], name: "index_beholders_on_deprecated_member_id"
    t.index ["post_id", "deprecated_member_id"], name: "index_beholders_on_post_id_and_deprecated_member_id", unique: true
    t.index ["post_id"], name: "index_beholders_on_post_id"
    t.index ["user_id"], name: "index_beholders_on_user_id"
  end

  create_table "blinds", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "issue_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["issue_id"], name: "index_blinds_on_issue_id"
    t.index ["user_id"], name: "index_blinds_on_user_id"
  end

  create_table "bookmarks", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "bookmarkable_type", null: false
    t.bigint "bookmarkable_id", null: false
    t.datetime "bookmarkable_created_at"
    t.index ["bookmarkable_type", "bookmarkable_id"], name: "index_bookmarks_on_bookmarkable_type_and_bookmarkable_id"
    t.index ["user_id", "bookmarkable_id", "bookmarkable_type"], name: "index_bookmarks_on_user_id_and_bookmarkable", unique: true
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "categories", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name", null: false
    t.string "group_slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position"
    t.index ["group_slug", "name"], name: "categories_uniq", unique: true
    t.index ["group_slug"], name: "index_categories_on_group_slug"
  end

  create_table "comment_authors", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "comment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["comment_id"], name: "index_comment_authors_on_comment_id"
    t.index ["user_id", "comment_id"], name: "index_comment_authors_on_user_id_and_comment_id", unique: true
    t.index ["user_id"], name: "index_comment_authors_on_user_id"
  end

  create_table "comment_histories", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.bigint "comment_id", null: false
    t.bigint "user_id", null: false
    t.text "body", limit: 16777215
    t.string "code", null: false
    t.integer "diff_body_adds_count", default: 0
    t.integer "diff_body_removes_count", default: 0
    t.boolean "trivial_update_body", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["comment_id"], name: "index_comment_histories_on_comment_id"
    t.index ["user_id"], name: "index_comment_histories_on_user_id"
  end

  create_table "comment_readers", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "comment_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["comment_id"], name: "index_comment_readers_on_comment_id"
    t.index ["user_id"], name: "index_comment_readers_on_user_id"
  end

  create_table "comments", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "post_id", null: false
    t.text "body", limit: 16777215
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "choice"
    t.datetime "deleted_at"
    t.integer "upvotes_count", default: 0
    t.integer "file_sources_count", default: 0
    t.integer "parent_id"
    t.datetime "almost_deleted_at"
    t.integer "comments_count", default: 0, null: false
    t.bigint "wiki_history_id"
    t.boolean "is_html", default: false
    t.boolean "is_decision", default: false
    t.integer "last_comment_history_id"
    t.integer "comment_histories_count", default: 0
    t.integer "last_author_id", null: false
    t.index ["deleted_at"], name: "index_comments_on_deleted_at"
    t.index ["parent_id"], name: "index_comments_on_parent_id"
    t.index ["post_id"], name: "index_comments_on_post_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
    t.index ["wiki_history_id"], name: "index_comments_on_wiki_history_id"
  end

  create_table "decision_histories", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "post_id", null: false
    t.integer "user_id"
    t.text "body", limit: 16777215
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "mailed_at"
    t.integer "diff_body_adds_count", default: 0
    t.integer "diff_body_removes_count", default: 0
    t.index ["post_id"], name: "index_decision_histories_on_post_id"
    t.index ["user_id"], name: "index_decision_histories_on_user_id"
  end

  create_table "device_tokens", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "registration_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "application_id", null: false
    t.index ["registration_id"], name: "index_device_tokens_on_registration_id"
    t.index ["user_id", "registration_id"], name: "index_device_tokens_on_user_id_and_registration_id", unique: true
    t.index ["user_id"], name: "index_device_tokens_on_user_id"
  end

  create_table "discussions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "title"
    t.text "body", limit: 16777215
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_discussions_on_deleted_at"
  end

  create_table "events", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "title", null: false
    t.datetime "start_at"
    t.datetime "end_at"
    t.boolean "all_day_long", default: false
    t.string "location"
    t.text "body"
    t.boolean "enable_self_attendance", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "feedbacks", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "survey_id", null: false
    t.integer "option_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["option_id"], name: "index_feedbacks_on_option_id"
    t.index ["survey_id"], name: "index_feedbacks_on_survey_id"
    t.index ["user_id", "option_id"], name: "index_feedbacks_on_user_id_and_option_id", unique: true
    t.index ["user_id"], name: "index_feedbacks_on_user_id"
  end

  create_table "file_sources", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name", null: false
    t.string "deprecated_attachment"
    t.string "file_type", null: false
    t.integer "file_size", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "post_id"
    t.integer "seq_no", default: 0, null: false
    t.string "attachment", null: false
    t.integer "image_width", default: 0
    t.integer "image_height", default: 0
    t.integer "file_sourceable_id", null: false
    t.string "file_sourceable_type", null: false
    t.index ["file_sourceable_type", "file_sourceable_id"], name: "file_sourceable_index"
    t.index ["post_id"], name: "index_file_sources_on_post_id"
  end

  create_table "folders", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "user_id"
    t.integer "issue_id", null: false
    t.string "title", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "parent_id"
    t.integer "children_count", default: 0
    t.integer "folder_seq", default: 0
    t.index ["issue_id"], name: "index_folders_on_issue_id"
    t.index ["parent_id"], name: "index_folders_on_parent_id"
    t.index ["title"], name: "index_folders_on_title"
    t.index ["user_id"], name: "index_folders_on_user_id"
  end

  create_table "group_home_components", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.string "title", null: false
    t.string "format_name", null: false
    t.integer "seq_no", null: false
    t.index ["group_id"], name: "index_group_home_components_on_group_id"
  end

  create_table "group_observations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "group_id", null: false
    t.string "payoff_create_comment", default: "ignoring"
    t.string "payoff_closed_survey", default: "ignoring"
    t.string "payoff_create_post", default: "ignoring"
    t.string "payoff_pin_post", default: "ignoring"
    t.string "payoff_mention", default: "subscribing_and_app_push"
    t.string "payoff_upvote", default: "subscribing_and_app_push"
    t.string "payoff_create_issue", default: "ignoring"
    t.string "payoff_update_issue_title", default: "ignoring"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_group_observations_on_group_id"
    t.index ["user_id", "group_id"], name: "index_group_observations_on_user_id_and_group_id", unique: true
    t.index ["user_id"], name: "index_group_observations_on_user_id"
  end

  create_table "group_push_notification_preferences", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "group_id", null: false
    t.index ["group_id"], name: "index_group_push_notification_preferences_on_group_id"
    t.index ["user_id", "group_id"], name: "group_push_notification_preferences_uk", unique: true
    t.index ["user_id"], name: "index_group_push_notification_preferences_on_user_id"
  end

  create_table "groups", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "title", null: false
    t.string "site_title"
    t.string "head_title"
    t.text "site_description", limit: 16777215
    t.text "site_keywords", limit: 16777215
    t.string "slug", null: false
    t.datetime "deleted_at"
    t.string "active", default: "on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "private", default: false, null: false
    t.integer "members_count", default: 0, null: false
    t.string "magic_key"
    t.string "plan", null: false
    t.string "key_visual_foreground_image"
    t.string "key_visual_background_image"
    t.integer "hot_score", default: 0
    t.string "hot_score_datestamp"
    t.integer "issues_count", default: 0
    t.integer "latest_stroked_posts_count", default: 0
    t.integer "latest_stroked_posts_count_version", default: 0
    t.integer "latest_issues_count", default: 0
    t.integer "latest_issues_count_version", default: 0
    t.bigint "main_wiki_post_id"
    t.bigint "main_wiki_post_by_id"
    t.string "issue_creation_privileges", default: "member", null: false
    t.bigint "blinded_by_id"
    t.datetime "blinded_at"
    t.string "logo", null: false
    t.boolean "frontable", default: false, null: false
    t.string "navbar_bg_color", default: "#5e2abb"
    t.string "navbar_text_color", default: "#ffffff"
    t.string "coc_text_color", default: "#ffffff"
    t.string "coc_btn_bg_color", default: "#5e2abb"
    t.string "coc_btn_text_color", default: "#ffffff"
    t.string "navbar_coc_text_color", default: "#5e2abb"
    t.string "organization_slug", default: "default"
    t.integer "labels_count", default: 0
    t.datetime "freezed_at"
    t.index ["blinded_by_id"], name: "index_groups_on_blinded_by_id"
    t.index ["main_wiki_post_by_id"], name: "index_groups_on_main_wiki_post_by_id"
    t.index ["main_wiki_post_id"], name: "index_groups_on_main_wiki_post_id"
    t.index ["slug", "active"], name: "index_groups_on_slug_and_active", unique: true
  end

  create_table "invitations", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "recipient_id"
    t.integer "joinable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "recipient_email"
    t.string "joinable_type", null: false
    t.text "message", limit: 16777215
    t.string "token", null: false
    t.index ["joinable_id", "joinable_type"], name: "index_invitations_on_joinable_id_and_joinable_type"
    t.index ["joinable_id"], name: "index_invitations_on_joinable_id"
    t.index ["recipient_id"], name: "index_invitations_on_recipient_id"
    t.index ["user_id"], name: "index_invitations_on_user_id"
  end

  create_table "issue_observations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "issue_id", null: false
    t.string "payoff_create_comment", default: "ignoring"
    t.string "payoff_closed_survey", default: "ignoring"
    t.string "payoff_create_post", default: "ignoring"
    t.string "payoff_pin_post", default: "ignoring"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["issue_id"], name: "index_issue_observations_on_issue_id"
    t.index ["user_id", "issue_id"], name: "index_issue_observations_on_user_id_and_issue_id", unique: true
    t.index ["user_id"], name: "index_issue_observations_on_user_id"
  end

  create_table "issue_posts_formats", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.bigint "group_home_component_id", null: false
    t.bigint "issue_id", null: false
    t.index ["group_home_component_id"], name: "index_issue_posts_formats_on_group_home_component_id"
    t.index ["issue_id"], name: "index_issue_posts_formats_on_issue_id"
  end

  create_table "issue_push_notification_preferences", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "issue_id", null: false
    t.string "value", null: false
    t.index ["issue_id"], name: "index_issue_push_notification_preferences_on_issue_id"
    t.index ["user_id", "issue_id"], name: "issue_push_notification_preferences_uk", unique: true
    t.index ["user_id"], name: "index_issue_push_notification_preferences_on_user_id"
  end

  create_table "issue_readers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "issue_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sort", default: "stroked"
    t.index ["issue_id"], name: "index_issue_readers_on_issue_id"
    t.index ["user_id"], name: "index_issue_readers_on_user_id"
  end

  create_table "issues", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "body", limit: 16777215
    t.string "logo"
    t.integer "watches_count", default: 0
    t.string "slug"
    t.integer "posts_count", default: 0
    t.datetime "deleted_at"
    t.string "active", default: "on"
    t.string "group_slug", null: false
    t.string "telegram_link"
    t.datetime "last_stroked_at"
    t.integer "members_count", default: 0
    t.integer "hot_score", default: 0
    t.string "hot_score_datestamp"
    t.datetime "freezed_at"
    t.boolean "private", default: false, null: false
    t.integer "last_stroked_user_id"
    t.boolean "notice_only", default: false
    t.boolean "is_default", default: false
    t.integer "destroyer_id"
    t.integer "latest_stroked_posts_count", default: 0
    t.integer "latest_stroked_posts_count_version"
    t.integer "category_id"
    t.boolean "listable_even_private", default: false
    t.bigint "blinded_by_id"
    t.datetime "blinded_at"
    t.integer "position", default: 0, null: false
    t.bigint "main_wiki_post_id"
    t.bigint "main_wiki_post_by_id"
    t.index ["blinded_by_id"], name: "index_issues_on_blinded_by_id"
    t.index ["category_id"], name: "index_issues_on_category_id"
    t.index ["deleted_at"], name: "index_issues_on_deleted_at"
    t.index ["group_slug", "slug", "active"], name: "index_issues_on_group_slug_and_slug_and_active", unique: true
    t.index ["group_slug", "title", "active"], name: "index_issues_on_group_slug_and_title_and_active", unique: true
    t.index ["last_stroked_user_id"], name: "index_issues_on_last_stroked_user_id"
    t.index ["main_wiki_post_by_id"], name: "index_issues_on_main_wiki_post_by_id"
    t.index ["main_wiki_post_id"], name: "index_issues_on_main_wiki_post_id"
  end

  create_table "labels", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.bigint "deprecated_issue_id"
    t.string "title", null: false
    t.string "body"
    t.integer "posts_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "group_id"
    t.index ["deprecated_issue_id"], name: "index_labels_on_deprecated_issue_id"
    t.index ["group_id"], name: "index_labels_on_group_id"
  end

  create_table "likes", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "post_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_likes_on_post_id"
    t.index ["user_id", "post_id"], name: "index_likes_on_user_id_and_post_id", unique: true
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "link_sources", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "title"
    t.text "body", limit: 16777215
    t.text "metadata", limit: 16777215
    t.string "image"
    t.string "page_type"
    t.string "url", limit: 700
    t.string "crawling_status", null: false
    t.datetime "crawled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "site_name"
    t.integer "image_height", default: 0
    t.integer "image_width", default: 0
    t.index ["url"], name: "index_link_sources_on_url", unique: true
  end

  create_table "member_requests", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "joinable_id", null: false
    t.integer "user_id", null: false
    t.datetime "deleted_at"
    t.string "active", default: "on"
    t.text "reject_message", limit: 16777215
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "joinable_type", null: false
    t.string "description"
    t.text "statement"
    t.index ["joinable_id", "joinable_type", "user_id", "active"], name: "unique_member_requests", unique: true
    t.index ["joinable_id", "joinable_type"], name: "index_member_requests_on_joinable_id_and_joinable_type"
    t.index ["user_id"], name: "index_member_requests_on_user_id"
  end

  create_table "members", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "joinable_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "joinable_type", null: false
    t.boolean "is_organizer", default: false, null: false
    t.datetime "deleted_at"
    t.string "active", default: "on"
    t.text "ban_message", limit: 16777215
    t.text "admit_message", limit: 16777215
    t.boolean "is_magic", default: false
    t.text "description", limit: 16777215
    t.datetime "read_at"
    t.string "role"
    t.text "statement"
    t.index ["joinable_id", "joinable_type"], name: "index_members_on_joinable_id_and_joinable_type"
    t.index ["joinable_id"], name: "index_members_on_joinable_id"
    t.index ["user_id", "joinable_id", "joinable_type", "active"], name: "index_members_on_user_id_and_joinable_id_and_joinable_type", unique: true
    t.index ["user_id"], name: "index_members_on_user_id"
  end

  create_table "mentions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "mentionable_id", null: false
    t.string "mentionable_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mentionable_type", "mentionable_id"], name: "index_mentions_on_mentionable_type_and_mentionable_id"
    t.index ["user_id", "mentionable_id", "mentionable_type"], name: "uniq_user_mention", unique: true
    t.index ["user_id"], name: "index_mentions_on_user_id"
  end

  create_table "merged_issues", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "source_id", null: false
    t.string "source_slug", null: false
    t.integer "issue_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "source_group_slug"
    t.index ["issue_id"], name: "index_merged_issues_on_issue_id"
    t.index ["source_id", "issue_id"], name: "index_merged_issues_on_source_id_and_issue_id", unique: true
    t.index ["source_id"], name: "index_merged_issues_on_source_id"
    t.index ["source_slug"], name: "index_merged_issues_on_source_slug"
    t.index ["user_id"], name: "index_merged_issues_on_user_id"
  end

  create_table "messages", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "messagable_id", null: false
    t.string "messagable_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "action"
    t.text "action_params"
    t.integer "sender_id", null: false
    t.datetime "read_at"
    t.string "bulk_session"
    t.string "cluster_owner_type"
    t.bigint "cluster_owner_id"
    t.string "group_slug"
    t.index ["cluster_owner_type", "cluster_owner_id"], name: "index_messages_on_cluster_owner_type_and_cluster_owner_id"
    t.index ["messagable_type", "messagable_id"], name: "index_messages_on_messagable_type_and_messagable_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "my_menus", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "issue_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["issue_id"], name: "index_my_menus_on_issue_id"
    t.index ["user_id", "issue_id"], name: "index_my_menus_on_user_id_and_issue_id", unique: true
    t.index ["user_id"], name: "index_my_menus_on_user_id"
  end

  create_table "oauth_access_grants", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "resource_owner_id", null: false
    t.integer "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", limit: 16777215, null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "scopes"
    t.index ["application_id"], name: "fk_rails_b4b53e07b8"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "resource_owner_id"
    t.integer "application_id"
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "fk_rails_732cb83ab7"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", limit: 16777215, null: false
    t.string "scopes", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "confidential", default: true, null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "options", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "survey_id", null: false
    t.text "body", limit: 16777215
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "feedbacks_count", default: 0
    t.integer "user_id", null: false
    t.datetime "canceled_at"
    t.index ["survey_id"], name: "index_options_on_survey_id"
    t.index ["user_id"], name: "index_options_on_user_id"
  end

  create_table "parti_sso_client_api_keys", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "digest"
    t.string "client"
    t.integer "authentication_id", null: false
    t.datetime "expires_at", null: false
    t.datetime "last_access_at", null: false
    t.boolean "is_locked", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client"], name: "index_parti_sso_client_api_keys_on_client"
    t.index ["user_id", "client"], name: "index_parti_sso_client_api_keys_on_user_id_and_client", unique: true
  end

  create_table "polls", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "title", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "votings_count", default: 0
    t.boolean "hidden_intermediate_result", default: false
    t.boolean "hidden_voters", default: false
    t.datetime "expires_at"
    t.integer "agree_votings_count", default: 0, null: false
    t.integer "neutral_votings_count", default: 0, null: false
    t.integer "disagree_votings_count", default: 0, null: false
    t.integer "sure_votings_count", default: 0, null: false
  end

  create_table "post_observations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "post_id", null: false
    t.string "payoff_create_comment", default: "ignoring"
    t.string "payoff_closed_survey", default: "ignoring"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_post_observations_on_post_id"
    t.index ["user_id", "post_id"], name: "index_post_observations_on_user_id_and_post_id", unique: true
    t.index ["user_id"], name: "index_post_observations_on_user_id"
  end

  create_table "post_readers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "post_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_post_readers_on_post_id"
    t.index ["user_id"], name: "index_post_readers_on_user_id"
  end

  create_table "post_searchable_indices", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "post_id", null: false
    t.text "ngram", limit: 4294967295
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["ngram"], name: "index_post_searchable_indices_on_ngram", type: :fulltext
    t.index ["post_id"], name: "index_post_searchable_indices_on_post_id"
  end

  create_table "posts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "issue_id", null: false
    t.integer "postable_id"
    t.string "postable_type"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "likes_count", default: 0
    t.integer "comments_count", default: 0
    t.integer "votes_count", default: 0
    t.datetime "deleted_at"
    t.string "social_card"
    t.integer "recommend_score", default: 0
    t.string "recommend_score_datestamp"
    t.datetime "last_commented_at"
    t.datetime "last_stroked_at"
    t.integer "upvotes_count", default: 0
    t.text "body", limit: 16777215
    t.integer "link_source_id"
    t.integer "poll_id"
    t.integer "survey_id"
    t.boolean "pinned", default: false
    t.datetime "pinned_at"
    t.integer "beholders_count", default: 0
    t.integer "last_stroked_user_id"
    t.integer "file_sources_count", default: 0
    t.string "last_stroked_for"
    t.integer "wiki_id"
    t.text "body_ngram", limit: 16777215
    t.text "decision", limit: 16777215
    t.integer "folder_id"
    t.bigint "event_id"
    t.string "base_title"
    t.integer "folder_seq", default: 0
    t.boolean "has_decision", default: false
    t.boolean "blind", default: false
    t.bigint "pinned_by_id"
    t.bigint "last_title_edited_user_id"
    t.bigint "label_id"
    t.bigint "announcement_id"
    t.boolean "has_decision_comments", default: false
    t.index ["announcement_id"], name: "index_posts_on_announcement_id"
    t.index ["deleted_at"], name: "index_posts_on_deleted_at"
    t.index ["event_id"], name: "index_posts_on_event_id"
    t.index ["folder_id"], name: "index_posts_on_folder_id"
    t.index ["issue_id"], name: "index_posts_on_issue_id"
    t.index ["label_id"], name: "index_posts_on_label_id"
    t.index ["last_stroked_user_id"], name: "index_posts_on_last_stroked_user_id"
    t.index ["last_title_edited_user_id"], name: "index_posts_on_last_title_edited_user_id"
    t.index ["link_source_id"], name: "index_posts_on_reference_type_and_reference_id"
    t.index ["pinned_by_id"], name: "index_posts_on_pinned_by_id"
    t.index ["poll_id"], name: "index_posts_on_poll_id"
    t.index ["postable_type", "postable_id"], name: "index_posts_on_postable_type_and_postable_id"
    t.index ["survey_id"], name: "index_posts_on_survey_id"
    t.index ["user_id"], name: "index_posts_on_user_id"
    t.index ["wiki_id"], name: "index_posts_on_wiki_id"
  end

  create_table "questions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "title"
    t.text "body", limit: 16777215
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "redactor2_assets", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "user_id"
    t.string "data_file_name"
    t.string "data_content_type"
    t.integer "data_file_size"
    t.integer "assetable_id"
    t.string "assetable_type", limit: 30
    t.string "type", limit: 30
    t.integer "width"
    t.integer "height"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["assetable_type", "assetable_id"], name: "idx_redactor2_assetable"
    t.index ["assetable_type", "type", "assetable_id"], name: "idx_redactor2_assetable_type"
  end

  create_table "relateds", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "issue_id", null: false
    t.integer "target_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["issue_id", "target_id"], name: "index_relateds_on_issue_id_and_target_id", unique: true
    t.index ["issue_id"], name: "index_relateds_on_issue_id"
    t.index ["target_id"], name: "index_relateds_on_target_id"
  end

  create_table "reports", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "reportable_type", null: false
    t.bigint "reportable_id", null: false
    t.bigint "user_id", null: false
    t.string "reason", default: "etc", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reportable_type", "reportable_id"], name: "index_reports_on_reportable_type_and_reportable_id"
    t.index ["user_id"], name: "index_reports_on_user_id"
  end

  create_table "roles", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.integer "resource_id"
    t.string "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["name"], name: "index_roles_on_name"
  end

  create_table "roll_calls", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "event_id", null: false
    t.string "status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "inviter_id"
    t.index ["event_id"], name: "index_roll_calls_on_event_id"
    t.index ["inviter_id"], name: "index_roll_calls_on_inviter_id"
    t.index ["user_id", "event_id"], name: "index_roll_calls_on_user_id_and_event_id", unique: true
    t.index ["user_id"], name: "index_roll_calls_on_user_id"
  end

  create_table "root_observations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.string "payoff_create_comment", default: "ignoring"
    t.string "payoff_closed_survey", default: "ignoring"
    t.string "payoff_create_post", default: "ignoring"
    t.string "payoff_pin_post", default: "ignoring"
    t.string "payoff_mention", default: "subscribing_and_app_push"
    t.string "payoff_upvote", default: "subscribing_and_app_push"
    t.string "payoff_create_issue", default: "ignoring"
    t.string "payoff_update_issue_title", default: "ignoring"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_root_observations_on_group_id", unique: true
  end

  create_table "searches", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "searchable_id", null: false
    t.string "searchable_type"
    t.text "content", limit: 16777215
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["searchable_type", "searchable_id"], name: "index_searches_on_searchable_type_and_searchable_id"
  end

  create_table "settings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "var", null: false
    t.text "value", limit: 16777215
    t.integer "thing_id"
    t.string "thing_type", limit: 30
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["thing_type", "thing_id", "var"], name: "index_settings_on_thing_type_and_thing_id_and_var", unique: true
  end

  create_table "statistics", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "when", null: false
    t.integer "join_users_count", null: false
    t.integer "posts_count", null: false
    t.integer "comments_count", null: false
    t.integer "upvotes_count", null: false
  end

  create_table "stroked_post_users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "post_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_stroked_post_users_on_post_id"
    t.index ["user_id"], name: "index_stroked_post_users_on_user_id"
  end

  create_table "summary_emails", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "code", null: false
    t.datetime "mailed_at"
    t.index ["code"], name: "index_summary_emails_on_code"
    t.index ["user_id", "code"], name: "index_summary_emails_on_user_id_and_code", unique: true
    t.index ["user_id"], name: "index_summary_emails_on_user_id"
  end

  create_table "surveys", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "feedbacks_count", default: 0
    t.integer "duration", default: 0
    t.datetime "sent_closed_message_at"
    t.datetime "expires_at"
    t.boolean "multiple_select", default: false
    t.boolean "hidden_intermediate_result", default: false
    t.boolean "hidden_option_voters", default: false
  end

  create_table "taggings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "tag_id"
    t.integer "taggable_id"
    t.string "taggable_type"
    t.integer "tagger_id"
    t.string "tagger_type"
    t.string "context", limit: 128
    t.datetime "created_at"
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
  end

  create_table "tags", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "upvotes", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "upvotable_id", null: false
    t.string "upvotable_type", null: false
    t.integer "issue_id"
    t.index ["issue_id"], name: "index_upvotes_on_issue_id"
    t.index ["user_id", "upvotable_id", "upvotable_type"], name: "index_upvotes_on_user_id_and_upvotable_id_and_upvotable_type", unique: true
    t.index ["user_id"], name: "index_upvotes_on_user_id"
  end

  create_table "users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "email"
    t.string "encrypted_password"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "nickname"
    t.string "image"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.string "uid"
    t.datetime "deleted_at"
    t.string "active", default: "on"
    t.boolean "enable_mailing_summary", default: true
    t.date "sent_new_posts_email_at"
    t.datetime "member_issues_changed_at"
    t.boolean "enable_mailing_member", default: false
    t.datetime "email_verified_at"
    t.string "push_notification_mode", default: "on"
    t.datetime "push_notification_enabled_at"
    t.datetime "push_notification_disabled_at"
    t.datetime "messages_read_at"
    t.boolean "enable_trace_device_token", default: false
    t.boolean "drawer_current_group_fixed_top", default: false
    t.boolean "drawer_current_group_unfold_only", default: false
    t.integer "last_visitable_id"
    t.string "last_visitable_type"
    t.datetime "canceled_at"
    t.string "touch_group_slug"
    t.integer "last_noticed_message_id"
    t.index ["confirmation_token", "active"], name: "index_users_on_confirmation_token_and_active", unique: true
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["nickname", "active"], name: "index_users_on_nickname_and_active", unique: true
    t.index ["provider", "uid", "active"], name: "index_users_on_provider_and_uid_and_active", unique: true
    t.index ["reset_password_token", "active"], name: "index_users_on_reset_password_token_and_active", unique: true
  end

  create_table "users_roles", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
  end

  create_table "votings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "poll_id", null: false
    t.string "choice", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["poll_id", "user_id"], name: "index_votings_on_poll_id_and_user_id", unique: true
    t.index ["poll_id"], name: "index_votings_on_poll_id"
    t.index ["user_id"], name: "index_votings_on_user_id"
  end

  create_table "watches", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "issue_id", null: false
    t.index ["issue_id"], name: "index_watches_on_issue_id"
    t.index ["user_id", "issue_id"], name: "index_watches_on_user_id_and_issue_id", unique: true
    t.index ["user_id"], name: "index_watches_on_user_id"
  end

  create_table "wiki_authors", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "wiki_id"
    t.index ["user_id", "wiki_id"], name: "index_wiki_authors_on_user_id_and_wiki_id", unique: true
    t.index ["user_id"], name: "index_wiki_authors_on_user_id"
    t.index ["wiki_id"], name: "index_wiki_authors_on_wiki_id"
  end

  create_table "wiki_histories", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "title", null: false
    t.integer "wiki_id", null: false
    t.integer "user_id", null: false
    t.text "body", limit: 4294967295
    t.string "code", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "diff_body_adds_count", default: 0
    t.integer "diff_body_removes_count", default: 0
    t.boolean "trivial_update_body", default: false, null: false
    t.index ["user_id"], name: "index_wiki_histories_on_user_id"
    t.index ["wiki_id"], name: "index_wiki_histories_on_wiki_id"
  end

  create_table "wikis", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.text "body", limit: 4294967295
    t.string "thumbnail"
    t.datetime "deleted_at"
    t.integer "last_author_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "status", default: "active", null: false
    t.integer "image_width", default: 0
    t.integer "image_height", default: 0
    t.integer "last_wiki_history_id"
    t.index ["last_author_id"], name: "index_wikis_on_last_author_id"
  end

  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
end
