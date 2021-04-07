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
      at = instance.last_stroked_at if at.blank?
      at = instance.created_at if at.blank?
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
  include Messagable

  acts_as_paranoid
  acts_as_taggable
  paginates_per 20

  belongs_to :issue, counter_cache: true
  belongs_to :label, counter_cache: true, optional: true
  has_one :group, through: :issue
  belongs_to :user
  belongs_to :last_title_edited_user, optional: true, class_name: 'User'
  belongs_to :poll, optional: true
  belongs_to :survey, optional: true
  belongs_to :announcement, optional: true
  belongs_to :link_source, optional: true
  belongs_to :wiki, optional: true
  belongs_to :event, optional: true
  belongs_to :pinned_by, class_name: 'User', optional: true
  has_many :file_sources, dependent: :destroy, as: :file_sourceable
  has_many :decision_histories, dependent: :destroy
  has_one :post_searchable_index, dependent: :destroy, autosave: true
  has_one :main_wiki_group, dependent: :nullify, class_name: "Group", foreign_key: :main_wiki_post_id
  has_one :main_wiki_issue, dependent: :nullify, class_name: "Issue", foreign_key: :main_wiki_post_id
  has_many :post_readers, dependent: :destroy
  has_one :current_user_post_reader,
    -> { where(user_id: Current.user.try(:id)) },
    class_name: 'PostReader'
  has_many :stroked_post_users, -> { recent }, dependent: :destroy
  has_many :post_observations, dependent: :destroy, class_name: 'MessageConfiguration::PostObservation'
  has_many :reports, dependent: :destroy, as: :reportable

  belongs_to :last_stroked_user, class_name: "User", optional: true
  accepts_nested_attributes_for :link_source
  accepts_nested_attributes_for :wiki
  accepts_nested_attributes_for :file_sources, allow_destroy: true, reject_if: proc { |attributes|
    attributes['attachment'].blank? and attributes['attachment_cache'].blank? and attributes['id'].blank?
  }
  accepts_nested_attributes_for :poll
  accepts_nested_attributes_for :survey
  accepts_nested_attributes_for :announcement
  accepts_nested_attributes_for :event

  has_many :comments, dependent: :destroy
  has_many :current_user_comments,
    -> { where(user_id: Current.user.try(:id)) },
    class_name: "Comment"

  has_many :beholders, dependent: :destroy
  belongs_to :folder, optional: true
  has_many :bookmarks, as: :bookmarkable, dependent: :destroy
  has_one :current_user_bookmark,
    -> { where(user_id: Current.user.try(:id)) },
    class_name: 'Bookmark', as: :bookmarkable

  # validations
  validates :issue, presence: true
  validates :user, presence: true
  validate :references_check
  validates :base_title, length: { maximum: 50 }, if: :base_title_changed?

  # scopes
  default_scope -> { joins(:issue) }
  scope :recent, -> { order(created_at: :desc) }
  scope :order_by_folder_seq, -> { order(folder_seq: :asc).order_by_stroked_at }
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
  scope :previous_of_time, ->(time) {
    if time.blank?
      all
    else
      where('posts.last_stroked_at < ?', Time.at(time.to_i).in_time_zone)
    end
  }
  scope :next_of_date, ->(date) { where('posts.last_stroked_at > ?', date) }
  scope :next_of_time, ->(time) { next_of_date(Time.at(time.to_i).in_time_zone) }
  scope :next_of_post, ->(post) { next_of_date(post.last_stroked_at) if post.present? }
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
  scope :deprecated_not_private_blocked_of_group, ->(group, someone) {
    if group.blank?
      of_searchable_issues(someone)
    else
      where(issue_id: group.issues.deprecated_not_private_blocked(someone))
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
  scope :having_poll, -> { where.not(poll_id: nil) }
  scope :having_survey, -> { where.not(survey_id: nil) }
  scope :having_image_file_sources, -> { where(id: FileSource.only_image.select('post_id')) }
  scope :having_image_link_sources, -> { where(link_source_id: LinkSource.has_image) }
  scope :of_issue, ->(issue) { where(issue_id: issue) }
  scope :of_group, ->(group) { where(issue_id: group.issues) }
  scope :pinned, -> { where(pinned: true) }
  scope :unpinned, -> { where.not(pinned: true) }
  scope :never_blinded, ->(someone = nil) {
    where.not(blind: true) if someone.nil? || !Blind.any_wide?(someone)
  }
  scope :unblinded, ->(someone) { where.not(blind: true).or(where(user_id: someone)) }
  scope :need_to_read_only, ->(someone) {
    if someone.blank?
      where('1 = 0')
    else
      joins("LEFT OUTER JOIN post_readers on post_readers.user_id = #{ActiveRecord::Base.connection.quote(someone.id)} AND post_readers.post_id = posts.id")
      .where('post_readers.id IS null or post_readers.updated_at < posts.last_stroked_at')
      .where('posts.last_stroked_at > ?', PostReader::VALID_PERIOD.ago)
      .where('posts.issue_id', IssueReader.where(user: someone).select(:issue_id))
    end
  }

  ## uploaders
  # mount
  mount_uploader :social_card, ImageUploader

  attr_accessor :has_poll
  attr_accessor :has_survey
  attr_accessor :has_event
  attr_accessor :is_html_body
  attr_accessor :conflicted_decision
  attr_accessor :title

  # fulltext serch
  before_save :reindex_for_search
  # hashtagging
  before_save :reindex_hashtags
  # blind
  before_save :process_blind

  def specific_desc_striped_tags(length = 0)
    desc = self.base_title.presence ||
      self.poll.try(:title).presence ||
      striped_tags(body).presence ||
      self.file_sources.first.try(:name).presence ||
      self.link_source.try(:title).presence

    desc = '(요약 없음)' if desc.blank?

    return desc if length <= 0
    return desc.try(:truncate, length)
  end

  def title
    base_title.presence || specific_desc_striped_tags(100).lines.find { |x| x.present? }
  end

  def share_image_dimensions
    [300, 158]
  end

  def viewed_by?(someone)
    return @_viewed_by if @_viewed_by.present?

    if someone.blank?
      @_viewed_by = false
      return false
    end

    if self.upvotes.exists?(user: someone)
      @_viewed_by = true
      return true
    end

    if self.behold_by?(someone)
      @_viewed_by = true
      return true
    end

    @_viewed_by = messagable_users.include?(someone)
    return @_viewed_by
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

    result = result.where(id: Member.where(joinable: self.group).select(:user_id))
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
    @_latest_comments_threaded = Comment.setup_threads(result, true)
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
    result = Comment.setup_threads(result, true)

    if limit > 0 and comments_count < result.flatten.count + Post::MORE_OFFSET_COMMENTS_COUNT
      result = more_comments_threaded(someone)
    end

    result
  end

  def any_not_latest_comments?(someone)
    comments_count > latest_comments_count(someone)
  end

  def commented_by_me?
    smart_exists_association?(:current_user_comments)
  end

  def blinded? someone = nil
    return false if someone.present? and someone.id == self.user_id
    issue.blind_user? self.user
  end

  def upvotable? someone
    return false if someone.blank?
    !upvotes.exists?(user: someone)
  end

  def main_wiki_group?
    issue.group.main_wiki_post == self
  end

  def main_wiki_issue?
    issue.main_wiki_post == self
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

  def build_wiki(params)
    if self.wiki.try(:persisted?)
      self.wiki.assign_attributes(params)
    else
      self.wiki = Wiki.new(params)
    end
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
    "#{self.title} | #{issue.title} 채널"
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

  def agree_by? voter
    poll.try(:agree_by?, voter)
  end

  def disagree_by? voter
    poll.try(:disagree_by?, voter)
  end

  def sured_by? voter
    poll.try(:sured_by?, voter)
  end

  def unsured_by? voter
    poll.try(:unsured_by?, voter)
  end

  def group_for_message
    self.issue.group
  end

  def post_for_message
    self
  end

  def issue_for_message
    issue
  end

  def issue_for_bookmark
    issue
  end

  def post_for_bookmark
    self
  end

  def private_blocked?(someone = nil)
    return false if issue.blank?
    issue.private_blocked?(someone) or issue.group.try(:private_blocked?, someone)
  end

  def notifiy_pinned_now(someone)
    # Transaction을 걸지 않습니다
    SendMessage.run(source: self, sender: someone, action: :pin_post)
  end

  def strok_by(someone, subject = nil)
    self.last_stroked_at = DateTime.now
    self.last_stroked_user = (someone || self.user)
    self.last_stroked_for = subject

    StrokedPostUserJob.perform_async(self.id, self.last_stroked_user&.id) if self.id.present?

    self
  end

  def strok_by!(someone, subject = nil)
    update_columns(last_stroked_at: DateTime.now, last_stroked_user_id: someone&.id, last_stroked_for: subject)
    read!(someone)
    StrokedPostUserJob.perform_async(self.id, someone&.id)
  end

  def last_stroked_activity(with_creation = false, &block)
    result = if last_stroked_at.present? && last_stroked_user.present? && last_stroked_for.present?
      user_word = if block_given?
        yield last_stroked_user
      else
        "@#{last_stroked_user.nickname}님이"
      end
      [I18n.t("views.post.last_stroked_for.#{last_stroked_for}", default: nil, user_word: user_word), self.last_stroked_at]
    end

    if wiki.present? and wiki.last_history.present?
      if result.blank? or wiki.last_history.created_at >= last_stroked_at
        result = wiki.last_activity(&block)
      end
    end

    if with_creation
      user_word = if block_given?
        yield self.user
      else
        "@#{self.user.nickname}님이"
      end
      if result.blank?
        result = [I18n.t("views.post.last_stroked_for.create", default: nil, user_word: user_word), self.created_at]
      end
    end

    result
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

  def process_blind
    self.blind = self.issue.blind_user?(self.user)
  end

  def decision_authors
    User.where(id: decision_histories.select(:user_id).distinct)
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
    return false if someone.blank?
    bookmarks.exists?(user: someone)
  end

  def bookmark_by(someone)
    bookmarks.find_by(user: someone) if someone.present?
  end

  def self.of_group_for_message(group)
    self.of_group(group)
  end

  def self.of_group_for_bookmark(group)
    self.of_group(group)
  end

  def build_conflict_decision
    self.conflicted_decision = self.decision
    self.decision = self.decision_was
  end

  def diff_conflicted_decision
    self.decision_histories.last.diff_body(self.conflicted_decision)
  end

  def behold_by?(someone)
    return false if someone.blank?
    beholders.exists?(user: someone)
  end

  def can_beholder?(someone)
    someone.present? and self.pinned? and issue.member?(someone) and !private_blocked?(someone)
  end

  def need_to_behold?(someone)
    can_beholder?(someone) and !behold_by?(someone)
  end

  def safe_folder_id
    Folder.safe_id(self.folder_id)
  end

  def read!(someone)
    return if someone.blank?
    return unless group.member?(someone)

    post_reader = self.post_readers.find_or_create_by(user: someone)
    post_reader.updated_at = DateTime.now
    post_reader.save

    post_reader
  end

  def need_to_read?(someone)
    return false if someone.blank?
    return false unless PostReader.valid_period(self.last_stroked_at)
    return false unless group.member?(someone)
    return false unless IssueReader.exists?(user: someone, issue: self.issue)

    post_reader = self.post_readers.find_by(user: someone)
    post_reader.blank? || post_reader.updated_at < self.last_stroked_at
  end

  def deprecated_unread?(someone)
    self.issue.deprecated_unread_post?(someone, self.last_stroked_at)
  end

  def file_sources_only_image
    file_sources.load
    FileSource.array_sort_by_seq_no(file_sources.to_a).select &:image?
  end

  def file_sources_only_doc
    file_sources.load
    FileSource.array_sort_by_seq_no(file_sources.to_a).select &:doc?
  end

  def frontable?
    issue.frontable?
  end

  def reset_has_decision_comments!
    self.update_columns(has_decision_comments: comments.exists?(is_decision: true))
  end

  private

  def reindex_for_search
    self.build_post_searchable_index if self.post_searchable_index.blank?
    self.post_searchable_index.reindex if will_save_change_to_body?
  end

  def reindex_hashtags(force: false)
    if force || self.will_save_change_to_base_title? || self.will_save_change_to_body? || (self.wiki.present? && self.wiki.will_save_change_to_body?)
      self.tag_list.clear

      words = [self.body, self.base_title, self.wiki.try(:body)].map do |text|
        HTMLEntities.new.decode ::Catan::SpaceSanitizer.new.do(text)
      end.flatten.join(' ').split(/[[:space:]]/).uniq

      words.select { |w| w.starts_with?('#') }.map { |w| w[1..-1] }.each do |hashtag|
        self.tag_list.add(hashtag.gsub(/\A[[:space:]]+|[[:space:]]+\z/, ''))
      end
    end
  end

  def references_check
    if self.persisted? and self.poll_id_changed? and !self.poll_id_was.blank?
      raise "Post #{self.id} : Change Poll!  #{self.poll_id_was} ==> #{self.poll_id}"
    end

    if self.persisted? and self.survey_id_changed? and !self.survey_id_was.blank?
      raise "Post #{self.id} : Change Survey!  #{self.survey_id_was} ==> #{self.survey_id}"
    end

    if self.persisted? and self.announcement_id_changed? and !self.announcement_id_was.blank?
      raise "Post #{self.id} : Change Announcement!  #{self.announcement_id_was} ==> #{self.announcement_id}"
    end

    if self.persisted? and self.wiki_id_changed? and !self.wiki_id_was.blank?
      raise "Post #{self.id} : Change Wiki! #{self.wiki_id_was} ==> #{self.wiki_id}"
    end
  end
end
