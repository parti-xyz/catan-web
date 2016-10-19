class Talk < ActiveRecord::Base
  include Postable
  acts_as_paranoid
  acts_as :post, as: :postable

  belongs_to :section
  belongs_to :reference, polymorphic: true
  accepts_nested_attributes_for :reference

  validates :section, presence: true
  validates :title, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :latest, -> { after(1.day.ago) }
  scope :having_reference, -> { where.not(reference: nil) }
  scope :previous_of_recent, ->(talk) {
    base = recent
    base = base.where('talks.created_at < ?', talk.created_at) if talk.present?
    base
  }

  def specific_origin
    self
  end

  def has_presentation?
    body.present?
  end

  def is_presentation?(comment)
    return false unless has_presentation?
    comment == comments.first
  end

  def commenters
    comments.map(&:user).uniq.reject { |u| u == self.user }
  end

  def best_comment
    comments.where('comments.upvotes_count >= ?', (Rails.env.development? ? 0 : 3)).order(upvotes_count: :desc).limit(1).first
  end

  def sequential_comments_but_presentation
    self.has_presentation? ? self.comments.sequential.offset(1) : self.comments.sequential
  end

  def image
    return LinkSource.new.image if !has_image?
    reference.try(:image) or reference.try(:attachment)
  end

  def has_image?
    return false if reference.blank?
    reference.attributes["image"].present? or reference.try(:image?)
  end

  def site_name
    reference.try(:site_name)
  end

  def reference_url
    reference.try(:url)
  end

  def reference_title
    reference.try(:title) || reference.try(:url)
  end

  def reference_body
    reference.try(:body)
  end

  def file_source?
    reference.is_a? FileSource
  end

  def link_source?
    reference.is_a? LinkSource
  end

  def video_source?
    return false unless link_source?
    VideoInfo.usable?(reference.try(:url) || '')
  end

  def build_reference(params)
    self.reference = self.reference_type.constantize.new(params) if self.reference_type.present?
  end
end
