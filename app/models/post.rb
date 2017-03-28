class Post < ActiveRecord::Base
  include Grape::Entity::DSL

  entity do
    include Rails.application.routes.url_helpers
    include ApiEntityHelper

    expose :full do |instance, options|
      options[:type]
    end
    expose :id, :upvotes_count, :comments_count
    expose :user, using: User::Entity
    expose :issue, using: Issue::Entity, as: :parti
    expose :parsed_title do |instance|
      view_helpers.post_body_format_for_api(instance.parsed_title)
    end
    expose :parsed_body do |instance|
      view_helpers.post_body_format_for_api(instance.parsed_body)
    end
    expose :truncated_parsed_body do |instance|
      parsed_body = view_helpers.post_body_format_for_api(instance.parsed_body)
      view_helpers.smart_truncate_html(parsed_body, length: 220, ellipsis: "... <read-more/>")
    end
    expose :specific_desc_striped_tags
    with_options(format_with: lambda { |dt| dt.iso8601 }) do
      expose :created_at, :last_stroked_at
    end

    with_options(if: lambda { |instance, options| options[:current_user].present? }) do
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
      expose :latest_upvote_users, using: User::Entity do |instance|
        instance.upvotes.recent.limit(8).map &:user
      end
      expose :latest_upvotes, using: Upvote::Entity do |instance|
        instance.upvotes.recent.limit(8)
      end
      expose :latest_comments, using: Comment::Entity do |instance|
        instance.comments.recent.limit(2)
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
  include Mentionable
  mentionable :body

  acts_as_paranoid
  paginates_per 20

  belongs_to :issue, counter_cache: true
  belongs_to :user
  belongs_to :poll
  belongs_to :survey
  belongs_to :reference, polymorphic: true
  belongs_to :postable, polymorphic: true
  belongs_to :last_stroked_user, class_name: User
  accepts_nested_attributes_for :reference
  accepts_nested_attributes_for :poll
  accepts_nested_attributes_for :survey

  has_many :comments, dependent: :destroy do
    def users
      self.map(&:user).uniq
    end
  end

  has_many :readers, dependent: :destroy

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
  scope :previous_of_post, ->(post) { where('posts.last_stroked_at < ?', post.last_stroked_at) if post.present? }
  scope :next_of_time, ->(time) { where('posts.last_stroked_at > ?', Time.at(time.to_i).in_time_zone) }
  scope :next_of_post, ->(post) { where('posts.last_stroked_at > ?', post.last_stroked_at) if post.present? }
  scope :next_of_last_stroked_at, ->(date) { where('posts.last_stroked_at > ?', date) }
  scope :previous_of_recent, ->(post) {
    base = recent
    base = base.where('posts.created_at < ?', post.created_at) if post.present?
    base
  }

  scope :watched_by, ->(someone) { where(issue_id: someone.member_issues) }
  scope :by_postable_type, ->(t) { where(postable_type: t.camelize) }
  scope :latest, -> { after(1.day.ago) }
  scope :displayable_in_current_group, ->(group) { joins(:issue).where('issues.group_slug' => group.slug) if group.present? }

  scope :having_reference, -> { where.not(reference: nil) }
  scope :having_poll, -> { where.not(poll_id: nil) }
  scope :having_survey, -> { where.not(survey_id: nil) }
  scope :of_issue, ->(issue) { where(issue_id: issue) }
  scope :pinned, -> { where(pinned: true) }
  scope :unpinned, -> { where.not(pinned: true) }

  ## uploaders
  # mount
  mount_uploader :social_card, ImageUploader

  attr_accessor :has_poll
  attr_accessor :has_survey
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
    result = [user]
    result += comments.users

    if poll.present?
      result += User.where(id: poll.votings.select(:user_id))
    end

    if survey.present?
      result += User.where(id: survey.feedbacks.select(:user_id))
      result += User.where(id: survey.options.select(:user_id))
    end

    result.uniq
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

  def format_body
    if self.is_html_body == 'false'
      parsed_text = ApplicationController.helpers.simple_format(ERB::Util.h(self.body), {}, sanitize: false)
      self.body = ApplicationController.helpers.auto_link(parsed_text, html: {class: 'auto_link', target: '_blank'}, link: :urls, sanitize: false)
    end

    strip_empty_tags
  end

  def strip_empty_tags
    doc = Nokogiri::HTML self.body
    ps = doc.xpath '/html/body/*'
    first_text = -1
    last_text = 0
    ps.each_with_index do |p, i|
      next unless p.enum_for(:traverse).map.to_a.select(&:text?).map(&:text).map(&:strip).any?(&:present?)

      #found some text
      first_text = i if first_text == -1
      last_text = i
    end

    self.body = ps.slice(first_text .. last_text).to_s
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

  def build_survey(params)
    if self.survey.try(:persisted?)
      self.survey.assign_attributes(params)
    else
      self.survey = Survey.new(params) if self.has_survey == 'true'
    end
  end

  def meta_tag_title
    if poll.present?
      poll.title
    elsif parsed_title.present?
      parsed_title
    else
      parsed_body.gsub('\n', '').truncate(13)
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
    elsif survey.present?
      share_image_url = Rails.application.routes.url_helpers.survey_social_card_post_url(self, format: :png)
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

  def self.reject_blinds(posts, user)
    posts.to_a.reject{ |post| post.blinded?(user) }
  end

  def issue_for_message
    issue
  end

  def private_blocked?(someone = nil)
    issue.private_blocked?(someone) or issue.group.try(:private_blocked?, someone)
  end

  def read_by?(someone)
    readers.includes(:member).exists?('members.user_id': someone)
  end

  def notifiy_pinned_now(someone)
    # Transaction을 걸지 않습니다
    send_notifiy_pinned_emails(someone)
    MessageService.new(self, sender: someone, action: :pinned).call()
  end

  def strok_by(someone = nil)
    self.last_stroked_at = DateTime.now
    self.last_stroked_user = someone || self.user
    self
  end

  def strok_by!(someone = nil)
    update_columns(last_stroked_at: DateTime.now, last_stroked_user_id: someone || self.user)
  end

  private

  def send_notifiy_pinned_emails(someone)
    users = self.issue.member_users.where.not(id: someone)
    users.each do |user|
      PinMailer.notify(someone.id, user.id, self.id).deliver_later
    end
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
      setences = lines.first.split(/(?=(<\/p>|<br>))/)
      if setences.first.length < 100
        remains = (setences[1..-1] + lines[1..-1]).join
        [setences.first, remains]
      else
        [nil, body]
      end
    end
  end
end
