class Article < ActiveRecord::Base
  acts_as_paranoid
  acts_as :post, as: :postable

  belongs_to :link_source

  scope :recent, -> { order(created_at: :desc) }

  def origin
    self
  end

  def title
    link_source.present? ? (link_source.title || link_source.url)  : read_attribute(:title)
  end

  def body
    link_source.present? ? link_source.body : read_attribute(:body)
  end

  def has_image?
    return false if link_source.try(:image).blank?
    link_source.image.file.exists?
  end

  def is_talk?
    link_source.blank?
  end

  def image
    link_source.try(:image)
  end

  def self.merge_by_link!(article)
    post = article.acting_as
    targets = post.issue.articles.where(link: article.link).order(created_at: :asc)
    oldest = targets.first
    targets.each do |target|
      next if target == oldest or target.link_source.blank?
      target.comments.update_all(post_id: oldest.acting_as.id)
      target.likes.where.not(user: oldest.likes).find_each do |like|
        like.update_columns(post_id: oldest.acting_as.id)
      end
      target.likes.where(user: oldest.likes).find_each do |like|
        like.destroy
      end
      target.destroy
    end
  end
end
