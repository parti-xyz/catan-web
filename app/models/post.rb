class Post < ActiveRecord::Base
  include Grape::Entity::DSL

  entity do
    include Rails.application.routes.url_helpers
    include TruncateHtmlHelper

    expose :id, :upvotes_count, :comments_count
    expose :user, using: User::Entity
    expose :issue, using: Issue::Entity, as: :parti
    expose :parsed_title, :parsed_body
    expose :truncated_parsed_body do |instance|
      truncate_html(instance.parsed_body, length: 220, omission: "... <span class='more'>더보기</span>")
    end
    expose :specific_desc_striped_tags do |instance|
      instance.specific_desc_striped_tags;
    end
    with_options(format_with: lambda { |dt| dt.iso8601 }) do
      expose :created_at, :last_touched_at
    end

    with_options(if: lambda { |instance, options| !!options[:current_user] }) do
      expose :is_upvotable do |instance, options|
        instance.upvotable? options[:current_user]
      end
      expose :is_blinded do |instance, options|
        instance.blinded? options[:current_user]
      end
    end

    with_options(if: lambda { |instance, options| options[:type] == :full }) do
      expose :link_reference, using: LinkSource::Entity, if: lambda { |instance, options| instance.link_source? } do |instance|
        instance.reference
      end
      expose :file_reference, using: FileSource::Entity, if: lambda { |instance, options| instance.file_source? } do |instance|
        instance.reference
      end
      expose :poll, using: Poll::Entity, if: lambda { |instance, options| instance.poll.present? } do |instance|
        instance.poll
      end
      expose :comments, using: Comment::Entity do |instance|
        instance.comments.sequential
      end
    end

    expose :share do
      expose :url do |instance|
        polymorphic_url(instance)
      end

      expose :twitter_text do |instance|
        instance.meta_tag_description.truncate(50)
      end

      expose :kakaotalk_text do |instance|
        instance.meta_tag_description.truncate(100)
      end

      expose :kakaotalk_link_text do |instance|
        "빠띠 게시물로 이동하기"
      end

      with_options(if: lambda { |instance, options| instance.share_image_dimensions.present? }) do
        expose :kakaotalk_image_url do |instance|
          instance.meta_tag_image
        end
        expose :kakaotalk_image_width do |instance|
          instance.share_image_dimensions[0]
        end
        expose :kakaotalk_image_height do |instance|
          instance.share_image_dimensions[1]
        end
      end
    end
  end

  HOT_LIKES_COUNT = 3

  include Upvotable

  acts_as_paranoid
  paginates_per 20

  belongs_to :issue, counter_cache: true
  belongs_to :user
  belongs_to :section
  belongs_to :poll
  belongs_to :reference, polymorphic: true
  belongs_to :postable, polymorphic: true
  accepts_nested_attributes_for :reference
  accepts_nested_attributes_for :poll

  has_many :comments, dependent: :destroy do
    def users
      self.map(&:user).uniq
    end
  end
  has_many :votes, dependent: :destroy do
    def users
      self.map(&:user).uniq
    end

    def partial_included_with(someone)
      partial = recent.limit(100)
      if !partial.map(&:user).include?(someone)
        (partial.all << find_by(user: someone)).compact
      else
        partial.all
      end
    end

    def point
      agreed.count - disagreed.count
    end
  end

  # validations
  validates :issue, presence: true
  validates :user, presence: true

  # scopes
  default_scope -> { joins(:issue) }
  scope :recent, -> { order(created_at: :desc) }
  scope :hottest, -> { order(recommend_score_datestamp: :desc, recommend_score: :desc) }
  scope :previous_of_hottest, ->(post) {
    base = hottest.order(id: :desc)
    base = base.where('posts.recommend_score > 0')
    base = base.where.not(recommend_score_datestamp: nil)
    base = base.where.any_of(
      ['posts.recommend_score < ?', post.recommend_score],
      where('posts.recommend_score = ? and posts.recommend_score_datestamp < ?',
        post.recommend_score, post.recommend_score_datestamp),
      where('posts.recommend_score = ? and posts.recommend_score_datestamp = ? and posts.id < ?',
        post.recommend_score, post.recommend_score_datestamp, post.id)
    ) if post.present?
    base
  }
  scope :previous_of_post, ->(post) { where('posts.last_touched_at < ?', post.last_touched_at) if post.present? }
  scope :next_of_post, ->(post) { where('posts.last_touched_at > ?', post.last_touched_at) if post.present? }
  scope :next_of_last_touched_at, ->(date) { where('posts.last_touched_at > ?', date) }
  scope :previous_of_recent, ->(post) {
    base = recent
    base = base.where('posts.created_at < ?', post.created_at) if post.present?
    base
  }

  scope :watched_by, ->(someone) { where(issue_id: someone.member_issues) }
  scope :by_postable_type, ->(t) { where(postable_type: t.camelize) }
  scope :latest, -> { after(1.day.ago) }
  scope :only_group_or_all_if_blank, ->(group) { joins(:issue).where('issues.group_slug' => group.slug) if group.present? }

  scope :having_reference, -> { where.not(reference: nil) }
  scope :having_poll, -> { where.not(poll_id: nil) }
  scope :of_issue, ->(issue) { where(issue_id: issue) }


  ## uploaders
  # mount
  mount_uploader :social_card, ImageUploader

  # callbacks
  before_create :touch_last_touched_at
  after_create :touch_last_touched_at_of_issues

  attr_accessor :has_poll
  attr_accessor :is_html_body

  def specific_desc
    self.parsed_title || self.body || self.poll.try(:title) || (self.reference.try(:name) if self.file_source?) || (self.reference.try(:title) if self.link_source?)
  end

  def specific_desc_striped_tags
    ActionView::Base.full_sanitizer.sanitize(specific_desc).to_s.gsub('&lt;', '<').gsub('&gt;', '>')
  end

  def share_image_dimensions
    [300, 158]
  end

  def messagable_users
    (comments.users + (poll.try(:votings).try(:users) || [])).uniq
  end

  def latest_comments
    comments.recent.limit(2).reverse
  end

  def blinded? someone
    return false if someone == self.user
    issue.blind_user? self.user
  end

  def upvotable? someone
    return false if someone.blank?
    !upvotes.exists?(user: someone)
  end

  def self.recommends(exclude)
    result = recent.limit(10)
    if result.length < 10
      result += recent.limit(10)
      result = result.uniq
    end
    result - [exclude]
  end

  def self.hottest_count
    hottest.length
  end

  def parsed_title
    title, _ = parsed_title_and_body
    title
  end

  def parsed_body
    _, body = parsed_title_and_body
   body
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

  def format_linkable_body
    self.body = ApplicationController.helpers.autolink_format(self.body)
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

  def meta_tag_description
    if poll.present?
      poll.title
    else
      strip_body = body.try(:strip)
      strip_body = '' if strip_body.nil?
      ActionView::Base.full_sanitizer.sanitize(strip_body).to_s.gsub('&lt;', '<').gsub('&gt;', '>')
    end
  end

  def meta_tag_image
    if poll.present?
      share_image_url = Rails.application.routes.url_helpers.poll_social_card_post_url(self, format: :png)
    elsif link_source?
      share_image_url = image.md.url
    elsif file_source? and reference.image?
      share_image_url = reference.attachment.md.url
    else
      share_image_url = issue.logo.md.url
    end
    share_image_url = issue.logo.md.url unless share_image_url.present?
    share_image_url
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

  def touch_last_touched_at
    self.last_touched_at = DateTime.now
  end

  def touch_last_touched_at_of_issues
    self.issue.touch(:last_touched_at)
  end

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
