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

        opinion.comments.update_all post_id: talk.acting_as.id
        opinion.upvotes.update_all upvotable_id: talk.acting_as.id

        OpinionToTalk.create!(opinion: opinion, talk: talk)

        opinion.votes.each do |vote|
          voting = Voting.create!(user: vote.user, choice: vote.choice,
            created_at: vote.created_at, updated_at: vote.updated_at,
            poll: talk.poll)
        end
      end
    end
  end
end
