class Article < ActiveRecord::Base
  include UniqueSoftDeletable
  include Postable
  acts_as_unique_paranoid
  acts_as :post, as: :postable

  belongs_to :source, polymorphic: true
  accepts_nested_attributes_for :source

  validates :source, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :latest, -> { after(1.day.ago) }
  scope :visible, -> { where(hidden: false) }
  scope :previous_of_recent, ->(article) {
    base = recent
    base = base.where('articles.created_at < ?', article.created_at) if article.present?
    base
  }

  def specific_origin
    self
  end

  def title
    return '' if self.hidden?
    source.try(:title) || source.try(:url)
  end

  def source_body
    return '' if self.hidden?
    source.try(:body)
  end

  def site_name
    return '' if self.hidden?
    source.try(:site_name)
  end

  def has_image?
    return false if self.hidden?
    source.attributes["image"].present? or source.try(:image?)
  end

  def source_url
    source.try(:url)
  end

  def image
    return LinkSource.new.image if self.hidden? or !has_image?
    source.try(:image) or source.try(:attachment)
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

  def video_source?
    return false unless link_source?
    VideoInfo.usable?(source.try(:url) || '')
  end

  def build_source(params)
    self.source = self.source_type.constantize.new(params) if self.source_type.present?
  end

  LIMIT_CHAR = 50

  def smart_title_and_body
    return [source.try(:title) || source.try(:url) || source.try(:name), nil] unless body.present?

    first_line = strip_body.lines.first.strip
    remains = strip_body.lines[1..-1].join

    result = [first_line, remains]
    result = [first_line.truncate(Note::LIMIT_CHAR), strip_body] if first_line.length > Note::LIMIT_CHAR
    result = [strip_body, nil] if result[0].length > (strip_body.length*0.30)

    result
  end

  private

  def strip_body
    body.strip
  end

end
