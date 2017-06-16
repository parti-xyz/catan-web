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
      view_helpers.post_body_format(instance.parsed_title)
    end
    expose :parsed_body do |instance|
      view_helpers.post_body_format(instance.parsed_body)
    end
    expose :truncated_parsed_body do |instance|
      parsed_body = view_helpers.post_body_format(instance.parsed_body)
      result = view_helpers.smart_truncate_html(parsed_body, length: 220, ellipsis: "... <read-more></read-more>")
      (result == parsed_body ? nil : result)
    end
    expose :specific_desc_striped_tags
    with_options(format_with: lambda { |dt| dt.iso8601 }) do
      expose :created_at, :last_stroked_at
    end

    with_options(if: lambda { |instance, options| options[:current_user].present? }) do
      expose :is_upvoted_by_me do |instance, options|
        instance.upvoted_by? options[:current_user]
      end
      expose :is_upvotable do |instance, options|
        instance.upvotable? options[:current_user]
      end
      expose :is_blinded do |instance, options|
        instance.blinded? options[:current_user]
      end
    end

    with_options(if: lambda { |instance, options| options[:type] == :full }) do
      expose :link_source, using: LinkSource::Entity, if: lambda { |instance, options| instance.link_source.present? } do |instance|
        instance.link_source
      end
      expose :file_sources, using: FileSource::Entity, if: lambda { |instance, options| instance.file_sources.any? } do |instance|
        instance.file_sources
      end
      expose :poll, using: Poll::Entity, if: lambda { |instance, options| instance.poll.present? } do |instance|
        instance.poll
      end
      expose :survey, using: Survey::Entity, if: lambda { |instance, options| instance.survey.present? } do |instance|
        instance.survey
      end
      expose :latest_comments, using: Comment::Entity do |instance|
        if instance.comments_count <= 3
          instance.comments.recent.reverse
        else
          instance.comments.recent.limit(2).reverse
        end
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
  belongs_to :link_source
  has_many :file_sources, dependent: :destroy
  belongs_to :postable, polymorphic: true
  belongs_to :last_stroked_user, class_name: User
  accepts_nested_attributes_for :link_source
  accepts_nested_attributes_for :file_sources, allow_destroy: true, reject_if: proc { |attributes|
    attributes['attachment'].blank? and attributes['attachment_cache'].blank? and attributes['id'].blank?
  }
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

  scope :having_link_of_file, -> { any_of(where.not(link_source: nil), where('file_sources_count > 0')) }
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
    self.parsed_title || self.body || (ERB::Util.h(self.poll.try(:title)).presence) || (ERB::Util.h(self.file_sources.first.try(:name)).presence if self.file_sources.any?) || (ERB::Util.h(self.link_source.try(:title)).presence if self.link_source.present?)
  end

  def specific_desc_striped_tags(length = 0)
    result = sanitize_html specific_desc
    result = result.gsub(/\A\p{Space}*/, '') if result.present?

    return result if length <= 0
    return result.try(:truncate, length)
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

  LATEST_COMMENTS_LIMNIT_COUNT = 2
  def latest_comments
    if too_many_comments?
      comments.recent.limit(Post::LATEST_COMMENTS_LIMNIT_COUNT).reverse
    else
      comments.recent.reverse
    end
  end

  def not_latest_comments(limit)
    return [Comment.none, false] unless too_many_comments?
    [comments.recent.limit(limit).offset(Post::LATEST_COMMENTS_LIMNIT_COUNT).reverse, comments_count > limit + Post::LATEST_COMMENTS_LIMNIT_COUNT]
  end

  def too_many_comments?
    comments_count > (Post::LATEST_COMMENTS_LIMNIT_COUNT + 1)
  end

  def blinded? someone = nil
    return false if someone.present? and someone == self.user
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

  def video_source?
    return false unless link_source.present?
    link_source.is_video?
  end

  def format_body!
    format_body(true)
  end

  def format_body(force = false)
    if self.is_html_body == 'false' or force
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
    self.survey.try(:setup_expires_at)
  end

  def meta_tag_title
    post_title = if poll.present?
      sanitize_html poll.title
    elsif parsed_title.present?
      sanitize_html parsed_title
    else
      sanitize_html(parsed_body).gsub('\n', '').truncate(13)
    end

    post_title.present? ? "#{post_title.truncate(15)} | #{issue.title} 빠띠" : "#{issue.title} 빠띠"
  end

  def meta_tag_description
    if poll.present?
      poll.title
    else
      strip_body = body.try(:strip)
      strip_body = '' if strip_body.nil?
      sanitize_html(strip_body)
    end
  end

  def meta_tag_image
    share_image_url = issue.logo.md.url
    if poll.present?
      share_image_url = Rails.application.routes.url_helpers.poll_social_card_post_url(self, format: :png)
    elsif survey.present?
      share_image_url = Rails.application.routes.url_helpers.survey_social_card_post_url(self, format: :png)
    elsif link_source.present? and link_source.image?
      share_image_url = link_source.image.lg.url
    elsif file_sources.only_image.any?
      share_image_url = file_sources.only_image.first.attachment.lg.url
    end
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

  def self.reject_blinded_or_blocked(posts, user)
    posts.to_a.reject{ |post| post.blinded?(user) or post.private_blocked?(user) }
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

  def strok_by!(someone, subject)
    update_columns(last_stroked_at: DateTime.now, last_stroked_user_id: someone, last_stroked_for: subject)
  end

  def generous_strok_by!(someone, subject)
    if self.last_stroked_at.blank? or self.last_stroked_at < 2.hours.ago
      strok_by!(someone, subject)
      true
    else
      false
    end
  end

  def body_html?
    true
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
    if link_source.present? || file_sources.any? || poll.present?
      [nil, body]
    elsif strip_body.length < 100
      [body, nil]
    elsif strip_body.length < 250
      [nil, body]
    else
      setences = strip_body.lines.map { |l| l.split(/(?<=<\/p>)/) }.map { |s| s.split(/(?=<br>)/) }.flatten
      if setences.first.length < 100
        remains = setences[1..-1].join.strip
        [setences.first, remains]
      else
        [nil, body]
      end
    end
  end

  def sanitize_html text
    HTMLEntities.new.decode ActionView::Base.full_sanitizer.sanitize(text)
  end
end
