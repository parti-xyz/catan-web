class FeaturedIssue < ActiveRecord::Base
  mount_uploader :image, ImageUploader
  mount_uploader :mobile_image, ImageUploader

  def issue
    Issue.find_by(slug: slug, group_slug: nil)
  end

  def talk
    Talk.find_by(id: talk_id)
  end

  def article
    Article.find_by(id: article_id)
  end

  def opinion
    Opinion.find_by(id: opinion_id)
  end
end
