class Article < ActiveRecord::Base
  include UniqueSoftDeletable
  include Postable
  acts_as_unique_paranoid
  acts_as :post, as: :postable

  belongs_to :link_source
  accepts_nested_attributes_for :link_source
  belongs_to :post_issue, class_name: Post
  validates :link_source, presence: true

  scope :recent, -> { includes(:post).order('posts.last_commented_at desc') }
  scope :latest, -> { after(1.day.ago) }
  scope :visible, -> { where(hidden: false) }
  scope :previous_of_article, ->(article) { includes(:post).where('posts.last_commented_at < ?', article.acting_as.last_commented_at) if article.present? }

  def specific_origin
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

  def site_name
    return '' if self.hidden?
    link_source.try(:site_name)
  end

  def has_image?
    return false if self.hidden?
    link_source.attributes["image"].present?
  end

  def image
    return LinkSource.new.image if self.hidden?
    link_source.try(:image)
  end

  def image_height
    return 0 if self.hidden?
    link_source.try(:image_height) || 0
  end

  def image_width
    return 0 if self.hidden?
    link_source.try(:image_width) || 0
  end

  def self.unify_by_url!(article)
    post = article.acting_as
    targets = post.issue.articles.where(link_source: article.link_source).order(created_at: :asc)
    targets << article unless targets.include?(article)
    targets.to_a.sort_by!{ |a| (a.created_at || DateTime.now) }
    oldest = targets.first

    targets.each do |target|
      next if target == oldest or target.link_source.blank?
      target.comments.update_all(post_id: oldest.acting_as.id)
      target.destroy
    end
    Post.reset_counters(oldest.acting_as.id, :comments) if oldest.persisted?
    return (oldest.present? ? oldest : article)
  end
end
