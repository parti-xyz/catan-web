class Talk < ActiveRecord::Base
  include Postable
  acts_as_paranoid
  acts_as :post, as: :postable

  belongs_to :poll
  belongs_to :section
  belongs_to :reference, polymorphic: true
  accepts_nested_attributes_for :reference
  accepts_nested_attributes_for :poll

  validates :section, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :latest, -> { after(1.day.ago) }
  scope :having_reference, -> { where.not(reference: nil) }
  scope :having_poll, -> { where.not(poll_id: nil) }
  scope :previous_of_recent, ->(talk) {
    base = recent
    base = base.where('talks.created_at < ?', talk.created_at) if talk.present?
    base
  }

  attr_accessor :has_poll

  def specific_origin
    self
  end

  def has_presentation?
    body.present?
  end

  def parsed_title
    title, _ = parsed_title_and_body
    title
  end

  def parsed_body
    _, body = parsed_title_and_body
   body
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
    self.reference = reference_type.constantize.new(params) if self.reference_type.present?
  end

  def build_poll(params)
    self.poll = Poll.new(params) if self.has_poll == 'true'
  end

  def meta_tag_title
    if poll.present?
      poll.title
    else
      strip_body = body.try(:strip)
      strip_body = '' if strip_body.nil?
      lines = strip_body.lines
      lines.first
    end
  end

  private

  def parsed_title_and_body
    strip_body = body.try(:strip)
    strip_body = '' if strip_body.nil?
    if link_source? || file_source? || poll.present?
      [nil, body]
    elsif strip_body.length < 100
      [body, nil]
    elsif strip_body.length < 250
      [nil, body]
    else
      lines = strip_body.lines
      remains = lines[1..-1].join
      [lines.first, remains]
    end
  end
end
