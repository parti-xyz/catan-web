class Article < ActiveRecord::Base
  acts_as_paranoid
  acts_as :post, as: :postable

  belongs_to :link_source
  validates :link, presence: true
  validates :link_source, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :latest, -> { after(1.day.ago) }
  scope :visible, -> { where(hidden: false) }

  after_destroy :search_index_after_destroy
  after_save :search_index_after_save

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

  def link=(val)
    old_source = self.link_source
    new_source = LinkSource.find_or_create_by!(url: val) do |new_link_source|
      new_link_source.crawling_status = 'not_yet'
    end
    self.link_source = new_source
    old_source.search_indexing if old_source.present? and old_source != new_source
    write_attribute(:link, val)
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
      target.destroy
    end
    oldest
  end

  private

  def search_index_after_save
    self.link_source.search_indexing
  end

  def search_index_after_destroy
    self.link_source.search_indexing
  end
end
