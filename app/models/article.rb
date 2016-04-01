class Article < ActiveRecord::Base
  acts_as_paranoid
  acts_as :post, as: :postable

  belongs_to :link_source
  validates :link, presence: true
  validates :link_source, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :latest, -> { after(1.day.ago) }

  def origin
    self
  end

  def title
    return '' if self.hidden?
    link_source.try(:title) || link_source.url
  end

  def body
    return '' if self.hidden?
    link_source.try(:body)
  end

  def has_image?
    return false if self.hidden?
    return false if link_source.try(:image).blank?
    link_source.image.file.exists?
  end

  def image
    return nil if self.hidden?
    link_source.try(:image)
  end

  def self.merge_by_link!(article)
    post = article.acting_as
    targets = post.issue.articles.where(link: article.link).order(created_at: :asc)
    oldest = targets.first

    targets.each do |target|
      next if target == oldest or target.link_source.blank?
      target.comments.update_all(post_id: oldest.acting_as.id)
      target.likes.where.not(user: oldest.like_users).find_each do |like|
        like.update_columns(post_id: oldest.acting_as.id)
      end
      target.likes.where(user: oldest.like_users).find_each do |like|
        like.destroy
      end
      target.destroy
    end
    oldest
  end
end
