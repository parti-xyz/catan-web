class Post < ApplicationRecord
  include Grape::Entity::DSL
  entity do
    include Rails.application.routes.url_helpers
    include PartiUrlHelper

    expose :id
    expose :issue_id, as: :channelId
    expose :groupId do |instance|
      instance.group.id
    end
    expose :lastStroked do |instance|
      text, at = instance.last_stroked_activity
      { text: text, at: at.try(:iso8601) }
    end

    expose :user, using: User::Entity
    expose :user_id, as: :userId
    expose :upvotes_count, as: :upvotesCount
    expose :comments_count, as: :commentsCount
    expose :created_at, as: :createdAt do |instance|
      instance.created_at.iso8601
    end
    expose :url do |instance|
      smart_post_url(instance)
    end

    with_options(if: lambda { |instance, options| options[:current_user].present? and !instance.private_blocked?(options[:current_user]) and !instance.blinded?(options[:current_user]) }) do
      expose :body
      expose :specific_desc_striped_tags, as: :specificDescStripedTags

      with_options(if: lambda { |instance, options| options[:current_user].present? }) do
        expose :isUpvotedByMe do |instance, options|
          instance.upvoted_by? options[:current_user]
        end
        expose :isUpvotable do |instance, options|
          instance.upvotable? options[:current_user]
        end
      end

      # expose :link_source, if: lambda { |instance, options| instance.link_source.present? and instance.file_sources.blank? } do |instance, options|
      #   if instance.link_source.crawling_status == 'completed'
      #     ((Rails.cache.fetch ["api-link_source", instance.link_source.id], race_condition_ttl: 30.seconds, expires_in: 1.hours do
      #       LinkSource::Entity.represent(instance.link_source, options).serializable_hash
      #     end) || {}).merge(image_url: instance.link_source.image_url)
      #   else
      #     LinkSource::Entity.represent(instance.link_source, options).serializable_hash
      #   end
      # end
      # expose :file_sources, using: FileSource::Entity, if: lambda { |instance, options| instance.file_sources.any? } do |instance|
      #   instance.file_sources
      # end
      # expose :poll, using: Poll::Entity, if: lambda { |instance, options| instance.poll.present? } do |instance|
      #   instance.poll
      # end
      # expose :survey, using: Survey::Entity, if: lambda { |instance, options| instance.survey.present? } do |instance|
      #   instance.survey
      # end
      # expose :wiki, using: Wiki::Entity, if: lambda { |instance, options| instance.wiki.present? } do |instance|
      #   instance.wiki
      # end
    end
  end

  HOT_LIKES_COUNT = 3

  include AutoLinkableBody
  include Upvotable
  include Mentionable
  mentionable :body

  acts_as_paranoid
  acts_as_taggable
  paginates_per 20

  belongs_to :issue, counter_cache: true
  has_one :group, through: :issue
  belongs_to :user
  belongs_to :poll, optional: true
  belongs_to :survey, optional: true
  belongs_to :link_source, optional: true
  belongs_to :wiki, optional: true
  belongs_to :event, optional: true
  has_many :file_sources, dependent: :destroy, as: :file_sourceable
  has_many :messages, as: :messagable, dependent: :destroy
  has_many :decision_histories, dependent: :destroy
  has_one :post_searchable_index, dependent: :destroy, autosave: true
  has_one :front_wiki_group, dependent: :nullify,  class_name: "Group", foreign_key: :front_wiki_post_id

  belongs_to :last_stroked_user, class_name: "User", optional: true
  accepts_nested_attributes_for :link_source
  accepts_nested_attributes_for :wiki
  accepts_nested_attributes_for :file_sources, allow_destroy: true, reject_if: proc { |attributes|
    attributes['attachment'].blank? and attributes['attachment_cache'].blank? and attributes['id'].blank?
  }
  accepts_nested_attributes_for :poll
  accepts_nested_attributes_for :survey
  accepts_nested_attributes_for :event

  has_many :comments, dependent: :destroy
  has_many :readers, dependent: :destroy
  belongs_to :folder, optional: true
  has_many :bookmarks, dependent: :destroy

  # validations
  validates :issue, presence: true
  validates :user, presence: true

  # scopes
  default_scope -> { joins(:issue) }
  scope :recent, -> { order(created_at: :desc) }
  scope :order_by_stroked_at, -> { order(last_stroked_at: :desc).recent }
  scope :hottest, -> { order(recommend_score_datestamp: :desc, recommend_score: :desc) }
  scope :previous_of_hottest, ->(post) {
    base = hottest.order(id: :desc)
    base = base.where('posts.recommend_score > 0')
    base = base.where.not(recommend_score_datestamp: nil)
    base = base.where('posts.recommend_score < ?', post.recommend_score)
      .or(base.where('posts.recommend_score = ? and posts.recommend_score_datestamp < ?',
        post.recommend_score, post.recommend_score_datestamp))
      .or(base.where('posts.recommend_score = ? and posts.recommend_score_datestamp = ? and posts.id < ?',
        post.recommend_score, post.recommend_score_datestamp, post.id)) if post.present?
    base
  }
  scope :previous_of_post, ->(post) { where('posts.last_stroked_at < ?', post.last_stroked_at) if post.present? }
  scope :next_of_time, ->(time) { where('posts.last_stroked_at > ?', Time.at(time.to_i).in_time_zone) }
  scope :next_of_post, ->(post) { where('posts.last_stroked_at > ?', post.last_stroked_at) if post.present? }
  scope :next_of_last_stroked_at, ->(post) {
    where('posts.last_stroked_at >= ?', post.last_stroked_at).where.not(id: post.id)
  }
  scope :previous_of_recent, ->(post) {
    base = recent
    base = base.where('posts.created_at < ?', post.created_at) if post.present?
    base
  }
  scope :previous_of_stroked, ->(post) {
    base = order_by_stroked_at
    base = base.where('posts.last_stroked_at < ?', post.last_stroked_at).where('posts.created_at < ?', post.created_at) if post.present?
    base
  }

  scope :watched_by, ->(someone) { where(issue_id: someone.member_issues) }
  scope :by_postable_type, ->(t) { where(postable_type: t.camelize) }
  scope :latest, -> { after(1.day.ago) }
  scope :not_private_blocked_of_group, ->(group, someone) {
    if group.blank?
      of_searchable_issues(someone)
    else
      where(issue_id: group.issues.not_private_blocked(someone))
    end
  }
  scope :of_searchable_issues, ->(current_user = nil) {
    where(issue_id: Issue.post_searchable_issues(current_user))
  }
  scope :of_undiscovered_issues, ->(current_user = nil) {
    where(issue_id: Issue.undiscovered_issues(current_user))
  }
  scope :having_link_or_file, -> {
    where.not(link_source: nil).or(where('file_sources_count > 0'))
  }
  scope :having_wiki, ->(status = nil) {
    condition = where.not(wiki: nil)
    condition = condition.joins('LEFT OUTER JOIN wikis on wikis.id = posts.wiki_id').where('wikis.status': status) if status.present?
    condition
  }
  scope :having_wiki_sorted_by_title, ->(status) {
    having_wiki(status).order('wikis.title asc')
  }
  scope :having_poll, -> { where.not(poll_id: nil) }
  scope :having_survey, -> { where.not(survey_id: nil) }
  scope :having_image_file_sources, -> { where(id: FileSource.only_image.select('post_id')) }
  scope :having_image_link_sources, -> { where(link_source_id: LinkSource.has_image) }
  scope :of_issue, ->(issue) { where(issue_id: issue) }
  scope :of_group, ->(group) { where(issue_id: group.issues) }
  scope :pinned, -> { where(pinned: true) }
  scope :unpinned, -> { where.not(pinned: true) }
  scope :never_blinded, -> { where.not(user_id: Blind.select(:user_id)) }
  scope :unblinded, -> { where.not(issue_id: (Blind.where("blinds.user_id = posts.user_id").select(:issue_id)))}

  ## uploaders
  # mount
  mount_uploader :social_card, ImageUploader

  attr_accessor :has_poll
  attr_accessor :has_survey
  attr_accessor :has_event
  attr_accessor :is_html_body
  attr_accessor :conflicted_decision

  # fulltext serch
  before_save :reindex_for_search
  # hashtagging
  before_save :reindex_hashtags

  def specific_desc_striped_tags(length = 0)
    striped_body = body.try(:strip)
    striped_body = '' if striped_body.nil?
    sanitized_body = sanitize_html striped_body
    sanitized_body = nil if sanitized_body.blank?

    desc = sanitized_body.presence ||
      self.wiki.try(:title).presence ||
      self.poll.try(:title).presence ||
      self.file_sources.first.try(:name).presence ||
      self.link_source.try(:title).presence ||
      self.wiki.try(:title).presence

    return desc if length <= 0
    return desc.try(:truncate, length)
  end

  def share_image_dimensions
    [300, 158]
  end

  def reviewed_by?(someone)
    return false if someone.blank?
    return true if upvotes.exists?(user: someone)
    return true if read_by?(someone)
    messagable_users.include? someone
  end

  def messagable_users
    result = User.where(id: user)
    result = result.or(User.where(id: comments.select(:user_id)))
    result = result.or(User.where(id: bookmarks.select(:user_id)))

    if poll.present?
      result = result.or(User.where(id: poll.votings.select(:user_id)))
    end

    if survey.present?
      result = result.or(User.where(id: survey.feedbacks.select(:user_id)))
      result = result.or(User.where(id: survey.options.select(:user_id)))
    end

    if wiki.present?
      result = result.or(User.where(id: wiki.authors))
    end

    result = result.where(id: Member.where(joinable: self.issue).select(:user_id))
    result
  end

  def comments_threaded
    return @_comments_threaded if @_comments_threaded.present? and comments_count == @_cached_comment_count_for_comments_threaded
    @_cached_comment_count_for_comments_threaded = comments_count

    @_comments_threaded = Comment.setup_threads(self.comments)
    @_comments_threaded
  end

  LATEST_DEFAULT_COMMENTS_LIMNIT_COUNT = 2
  LATEST_UNREAD_COMMENTS_LIMNIT_COUNT = 20
  def latest_comments_threaded(someone)
    return @_latest_comments_threaded if @_latest_comments_threaded.present? and comments_count == @_cached_comment_count_for_latest_comments_threaded
    @_cached_comment_count_for_latest_comments_threaded = comments_count

    result = comments.recent.unread(someone).limit(Post::LATEST_UNREAD_COMMENTS_LIMNIT_COUNT)
    if result.count < Post::LATEST_DEFAULT_COMMENTS_LIMNIT_COUNT
      ids = result.to_a.map(&:id)
      ids += comments.recent.after(1.weeks.ago).limit(Post::LATEST_DEFAULT_COMMENTS_LIMNIT_COUNT).to_a.map(&:id)
      result = Comment.where(id: ids)
    end
    if last_stroked_for == 'comment' and result.empty?
      result = comments.recent.limit(1)
    end
    @_latest_comments_threaded = Comment.setup_threads(result)
    @_latest_comments_threaded
  end

  def latest_comments_count(someone)
    latest_comments_threaded(someone).flatten.count
  end

  MORE_OFFSET_COMMENTS_COUNT = 10
  def more_comments_threaded(someone, limit = -1)
    result = comments.recent
    result = result.limit(limit) if limit > 0
    result = result.reverse
    result = Comment.setup_threads(result)

    if limit > 0 and comments_count < result.flatten.count + Post::MORE_OFFSET_COMMENTS_COUNT
      result = more_comments_threaded(someone)
    end

    result
  end

  def any_not_latest_comments?(someone)
    comments_count > latest_comments_count(someone)
  end

  def blinded? someone = nil
    return false if someone.present? and someone.id == self.user_id
    issue.blind_user? self.user
  end

  def upvotable? someone
    return false if someone.blank?
    !upvotes.exists?(user: someone)
  end

  def front_wiki?
    self.issue.group.front_wiki_post == self
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

  def video_source?
    return false unless link_source.present?
    link_source.is_video?
  end

  def format_body!
    format_body(true)
  end

  def build_poll(params)
    if self.poll.try(:persisted?)
      self.poll.assign_attributes(params)
    else
      self.poll = Poll.new(params) if self.has_poll == 'true'
    end
    self.poll.try(:setup_expires_at)
  end

  def build_survey(params)
    if self.survey.try(:persisted?)
      self.survey.assign_attributes(params)
    else
      self.survey = Survey.new(params) if self.has_survey == 'true'
    end
    self.survey.try(:setup_expires_at)
  end

  def build_event(params)
    if self.event.try(:persisted?)
      self.event.assign_attributes(params)
    else
      if self.has_event == 'true'
        self.event = Event.new(params)
      end
    end
    self.event.try(:setup_schedule)
    self.event.try(:setup_location)
  end

  def meta_tag_title
    body.present? ? "#{sanitize_html(body).truncate(15)} | #{issue.title} 채널" : "#{issue.title} 채널"
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
    elsif file_sources.only_image.any?
      share_image_url = file_sources.only_image.first.attachment.lg.url
    elsif link_source.present? and link_source.image?
      share_image_url = link_source.image.lg.url
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

  def post_for_message
    self
  end

  def issue_for_message
    issue
  end

  def private_blocked?(someone = nil)
    return false if issue.blank?
    issue.private_blocked?(someone) or issue.group.try(:private_blocked?, someone)
  end

  def read_by?(someone)
    readers.exists?(user: someone)
  end

  def can_be_reader?(someone)
    issue.member?(someone) and !private_blocked?(someone)
  end

  def need_to_read?(someone)
    can_be_reader?(someone) and !read_by?(someone)
  end

  def notifiy_pinned_now(someone)
    # Transaction을 걸지 않습니다
    send_notifiy_pinned_emails(someone)
    MessageService.new(self, sender: someone, action: :pinned).call()
  end

  def careful_pin_by?(someone)
    return false if someone.blank?
    return false if pinned_at.blank?
    return false unless issue.organized_by?(someone)

    pinned_at < 1.week.ago
  end

  def strok_by(someone, subject = nil)
    self.last_stroked_at = DateTime.now
    self.last_stroked_user = (someone || self.user)
    self.last_stroked_for = subject
    self
  end

  def strok_by!(someone, subject)
    update_columns(last_stroked_at: DateTime.now, last_stroked_user_id: someone.id, last_stroked_for: subject)
  end

  def last_stroked_activity(&block)
    result = if last_stroked_at.present? and last_stroked_user.present? and last_stroked_for.present?
      user_word = if block_given?
        yield last_stroked_user
      else
        "@#{last_stroked_user.nickname}님이"
      end
      [I18n.t("views.post.last_stroked_for.#{last_stroked_for}", default: nil, user_word: user_word), self.last_stroked_at]
    end

    if wiki.present? and wiki.wiki_histories.any?
      if result.blank? or wiki.latest_history.created_at >= last_stroked_at
        return wiki.last_activity(&block)
      end
    end

    result
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

  def setup_link_source(body_was = '')
    if self.survey.blank? and self.poll.blank? and self.body.present?
      old_link = nil
      if self.link_source.present?
        old_link = self.link_source.url
      end

      links = find_all_a_tags(self.body).map { |t| encode_url(t['href']) }.compact.select { |url| LinkSource.valid_url?(url) }
      links_was = find_all_a_tags(body_was).map { |t| encode_url(t['href']) }.compact.select { |url| LinkSource.valid_url?(url) }

      first_link = links.first
      if first_link.present?
        if self.link_source.try(:url) != first_link
          self.link_source = LinkSource.new(url: first_link)
        end
      elsif old_link.present?
        if !links.include?(old_link) and links_was.include?(old_link)
          self.link_source = nil
        else
          self.body += "<p><a href='#{old_link}'>#{old_link}</a></p>"
        end
      end
    end
    self.link_source = self.link_source.unify if self.link_source.present?
  end

  def self.search(key)
    indices = PostSearchableIndex.search(key)
    if indices == PostSearchableIndex.all
      all
    else
      where(id: indices.select(:post_id))
    end
  end

  def reindex_for_search!
    self.create_post_searchable_index if self.post_searchable_index.blank?
    self.post_searchable_index.reindex!
  end

  def reindex_for_hashtags!
    reindex_hashtags(force: true)
    self.save_tags
  end

  def decision_authors_count
    decision_histories.select(:user_id).distinct.count
  end

  def decisionable? someone = nil
    wiki.blank? and issue.try(:postable?, someone)
  end

  def last_stroked_days_from_today
    (Date.today - self.last_stroked_at.to_date).to_i
  end

  def bookmarked?(someone)
    bookmarks.exists?(user: someone)
  end

  def bookmark_by(someone)
    bookmarks.find_by(user: someone)
  end

  def self.messagable_group_method
    :of_group
  end

  def build_conflict_decision
    self.conflicted_decision = self.decision
    self.decision = self.decision_was
  end

  def diff_conflicted_body
    self.decision_histories.last.diff_body(self.conflicted_decision)
  end

  private

  def reindex_for_search
    self.build_post_searchable_index if self.post_searchable_index.blank?
    self.post_searchable_index.reindex if will_save_change_to_body?
  end

  def reindex_hashtags(force: false)
    if force or self.will_save_change_to_body? or (self.wiki.present? and (self.wiki.will_save_change_to_body? or self.wiki.will_save_change_to_title?))
      self.tag_list.clear

      words = [self.body, self.wiki.try(:title), self.wiki.try(:body)].map do |text|
        HTMLEntities.new.decode ::Catan::SpaceSanitizer.new.do(text)
      end.flatten.join(' ').split(/[[:space:]]/).uniq

      words.select { |w| w.starts_with?('#') }.map { |w| w[1..-1] }.each do |hashtag|
        self.tag_list.add(hashtag.gsub(/\A[[:space:]]+|[[:space:]]+\z/, ''))
      end
    end
  end

  def send_notifiy_pinned_emails(someone)
    users = self.issue.member_users.where.not(id: someone)
    users.each do |user|
      PinMailer.notify(someone.id, user.id, self.id).deliver_later
    end
  end

  def sanitize_html text
    HTMLEntities.new.decode ::Catan::SpaceSanitizer.new.do(text)
  end
end
