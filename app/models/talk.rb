class Talk < ActiveRecord::Base
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
  scope :previous_of_recent, ->(post) {
    base = recent
    base = base.where('posts.created_at < ?', post.created_at) if post.present?
    base
  }

  attr_accessor :has_poll
  attr_accessor :is_html_body

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

  def format_linkable_body
    self.body = ApplicationController.helpers.autolink_format(self.body)
  end

  def video_source?
    return false unless link_source?
    VideoInfo.usable?(reference.try(:url) || '')
  end

  def build_reference(params)
    self.reference = reference_type.constantize.new(params) if self.reference_type.present?
  end

  def build_poll(params)
    if self.poll.try(:persisted?)
      self.poll.assign_attributes(params)
    else
      self.poll = Poll.new(params) if self.has_poll == 'true'
    end
  end

  def voting_by voter
    poll.try(:voting_by, voter)
  end

  def voting_by? voter
    poll.try(:voting_by?, voter)
  end

  def agreed_by? voter
    poll.try(:agreed_by?, voter)
  end

  def disagreed_by? voter
    poll.try(:disagreed_by?, voter)
  end

  def sured_by? voter
    poll.try(:sured_by?, voter)
  end

  def unsured_by? voter
    poll.try(:unsured_by?, voter)
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
      setences = lines.first.split(/(?<=\<\/p>)/)
      if setences.first.length < 100
        remains = (setences[1..-1] + lines[1..-1]).join
        [setences.first, remains]
      else
        [nil, body]
      end
    end
  end
end
