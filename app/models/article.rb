class Article < ActiveRecord::Base
  include UniqueSoftDeletable
  include Postable
  acts_as_unique_paranoid
  acts_as :post, as: :postable

  belongs_to :source, polymorphic: true
  accepts_nested_attributes_for :source

  validates :source, presence: true
  validates :body, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :latest, -> { after(1.day.ago) }
  scope :visible, -> { where(hidden: false) }
  scope :previous_of_article, ->(article) { includes(:post).where('posts.last_commented_at < ?', article.acting_as.last_commented_at) if article.present? }

  def specific_origin
    self
  end

  def title
    return '' if self.hidden?
    source.try(:title) || source.try(:url) || source.try(:name)
  end

  def source_body
    return '' if self.hidden?
    source.try(:body) || (comments.first.body if comments.any?)
  end

  def site_name
    return '' if self.hidden?
    source.try(:site_name)
  end

  def has_image?
    return false if self.hidden?
    source.attributes["image"].present?
  end

  def image
    return LinkSource.new.image if self.hidden?
    source.try(:image)
  end

  def image_height
    return 0 if self.hidden?
    source.try(:image_height) || 0
  end

  def image_width
    return 0 if self.hidden?
    source.try(:image_width) || 0
  end

  def file_source?
    source.is_a? FileSource
  end

  def link_source?
    source.is_a? LinkSource
  end

  def build_source(params)
    self.source = self.source_type.constantize.new(params) if self.source_type.present?
  end

  # def self.unify!(article)
  #   post = article.acting_as
  #   targets = post.issue.articles.where(source: article.source).order(created_at: :asc)
  #   targets << article unless targets.include?(article)
  #   targets.to_a.sort_by!{ |a| (a.created_at || DateTime.now) }
  #   oldest = targets.first

  #   targets.each do |target|
  #     next if target == oldest or target.source.blank?
  #     target.comments.update_all(post_id: oldest.acting_as.id)
  #     target.destroy
  #   end
  #   Post.reset_counters(oldest.acting_as.id, :comments) if oldest.persisted?
  #   return (oldest.present? ? oldest : article)
  # end
end
