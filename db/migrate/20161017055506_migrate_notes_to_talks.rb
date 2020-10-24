class MigrateNotesToTalks < ActiveRecord::Migration[4.2]
  class Note < ApplicationRecord
  end

  def up
    ActiveRecord::Base.transaction do
      Note.all.each do |note|
        talk_title, talk_body = note.smart_title_and_body
        talk = Talk.create!(title: talk_title, body: talk_body, created_at: note.created_at, updated_at: note.updated_at, issue: note.issue, section_id: note.issue.sections.initial_section.id, user: note.user)
        post = talk.acting_as
        post_note = note.acting_as
        note.comments.each do |comment|
          comment.update_attributes(post: post)
        end
        note.upvotes.each do |upvote|
          upvote.update_attributes(upvotable: post)
        end
        Post.reset_counters(post.id, :comments, :upvotes)
        post.update_columns(created_at: post_note.created_at, updated_at: post_note.updated_at, recommend_score: post_note.recommend_score, recommend_score_datestamp: post_note.recommend_score_datestamp , last_commented_at: post_note.last_commented_at, last_touched_at: post_note.last_touched_at)
      end
      Note.destroy_all
    end
  end
end
