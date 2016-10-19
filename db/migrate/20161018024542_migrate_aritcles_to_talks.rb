class MigrateAritclesToTalks < ActiveRecord::Migration
  def up
    remove_index(:articles, name: :index_article_on_unique_link_source)
    ActiveRecord::Base.transaction do
      LinkSource.all.each do |link_source|
        original_url = link_source.url
        if !(link_source.url.starts_with?('http://') or link_source.url.starts_with?('https://'))
          link_source.url = link_source.url.prepend('http://')
        end
        unless LinkSource::URL_FORMAT =~ link_source.url
          link_source.body = original_url
          link_source.url = "http://parti.xyz/404?id=#{link_source.id}"
        end

        if link_source.changed?
          origin = LinkSource.where(url: link_source.url).where.not(id: link_source.id).oldest
          if origin.present?
            link_source.articles.each do |article|
              article.source = origin
              article.save!
            end
            link_source.talks.each do |talk|
              talk.source = origin
              talk.save!
            end
            link_source.destroy!
          else
            link_source.save!
          end
        end
      end

      Article.all.each do |article|
        talk_title, talk_body = article.smart_title_and_body

        talk = Talk.create!(title: talk_title, body: talk_body,
          reference_id: article.source.id, reference_type: article.source.class.name,
          created_at: article.created_at, updated_at: article.updated_at,
          issue: article.issue, section_id: article.issue.sections.initial_section.id,
          user: article.user)

        post = talk.acting_as
        post_article = article.acting_as

        article.comments.each do |comment|
          comment.update_attributes(post: post)
        end
        article.upvotes.each do |upvote|
          upvote.update_attributes(upvotable: post)
        end
        Post.reset_counters(post.id, :comments, :upvotes)

        post.update_columns(created_at: post_article.created_at, updated_at: post_article.updated_at,
          recommend_score: post_article.recommend_score,
          recommend_score_datestamp: post_article.recommend_score_datestamp,
          last_commented_at: post_article.last_commented_at, last_touched_at: post_article.last_touched_at)
      end
      Article.destroy_all
    end
  end
end
