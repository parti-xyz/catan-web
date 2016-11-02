class MigrateOpinionsToTalks < ActiveRecord::Migration
  def up
    create_table :opinion_to_talks do |t|
      t.references :opinion
      t.references :talk
    end

    ActiveRecord::Base.transaction do
      Opinion.all.each do |opinion|
        talk = Talk.new(created_at: opinion.created_at, updated_at: opinion.updated_at,
          issue: opinion.issue, section_id: opinion.issue.sections.initial_section.id,
          user: opinion.user, has_poll: 'true')

        talk.build_poll(title: opinion.title)

        talk.save!

        OpinionToTalk.create!(opinion_id: opinion.id, talk: talk)

        opinion.votes.each do |vote|
          voting = Voting.create!(user: vote.user, choice: vote.choice,
            created_at: vote.created_at, updated_at: vote.updated_at,
            poll: talk.poll)
        end

        post = talk.acting_as
        post_opinion = opinion.acting_as

        opinion.comments.each do |comment|
          comment.update_attributes(post: post)
        end
        opinion.upvotes.each do |upvote|
          upvote.update_attributes(upvotable: post)
        end

        Post.reset_counters(post.id, :comments, :upvotes)

        post.update_columns(created_at: post_opinion.created_at, updated_at: post_opinion.updated_at,
          recommend_score: post_opinion.recommend_score,
          recommend_score_datestamp: post_opinion.recommend_score_datestamp,
          last_commented_at: post_opinion.last_commented_at, last_touched_at: post_opinion.last_touched_at)
      end

      Opinion.destroy_all
      Vote.destroy_all
    end
  end
end
