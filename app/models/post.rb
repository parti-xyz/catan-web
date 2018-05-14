class Post < ActiveRecord::Base
  include Grape::Entity::DSL

  entity do
    include Rails.application.routes.url_helpers
    include PartiUrlHelper
    include ApiEntityHelper

    expose :full do |instance, options|
      options[:type]
    end
    expose :id, :upvotes_count, :comments_count
    expose :user, using: User::Entity
    expose :parti do |instance, options|
      Rails.cache.fetch ["api-issue", instance.issue], race_condition_ttl: 30.seconds, expires_in: 1.hours do
        Issue::Entity.represent(instance.issue, options).serializable_hash
      end
    end
    expose :parsed_title do |instance|
      view_helpers.post_body_format(instance.issue, instance.parsed_title)
    end
    expose :parsed_body do |instance|
      view_helpers.post_body_format(instance.issue, instance.parsed_body)
    end
    expose :truncated_parsed_body do |instance|
      parsed_body = view_helpers.post_body_format(instance.issue, instance.parsed_body)
      result = view_helpers.smart_truncate_html(parsed_body, length: 220, ellipsis: "... <read-more></read-more>")
      (result == parsed_body ? nil : result)
    end
    expose :specific_desc_striped_tags
    with_options(format_with: lambda { |dt| dt.iso8601 }) do
      expose :created_at, :last_stroked_at
    end
    # 외부에 오픈된 API라 쉽게 바꾸지 못함
    # 추후 새로운 앱이 릴리즈되면 변경할 예정
    expose :latest_stroked_activity do |instance|
      instance.last_stroked_activity do |user|
        "<a href='#{smart_user_gallery_url(user)}'>@#{user.nickname}</a>"
      end
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
      expose :link_source, if: lambda { |instance, options| instance.link_source.present? and instance.file_sources.blank? } do |instance, options|
        if instance.link_source.crawling_status == 'completed'
          ((Rails.cache.fetch ["api-link_source", instance.link_source.id], race_condition_ttl: 30.seconds, expires_in: 1.hours do
            LinkSource::Entity.represent(instance.link_source, options).serializable_hash
          end) || {}).merge(image_url: instance.link_source.image_url)
        else
          LinkSource::Entity.represent(instance.link_source, options).serializable_hash
        end
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
      expose :wiki, using: Wiki::Entity, if: lambda { |instance, options| instance.wiki.present? } do |instance|
        instance.wiki
      end
      expose :latest_comments, using: Comment::Entity do |instance|
        instance.comments.recent.limit(5).reverse
      end
    end

    expose :url do |instance|
      smart_post_url(instance)
    end

    # expose :share do
    #   expose :url do |instance|
    #     polymorphic_url(instance)
    #   end

    #   expose :twitter_text do |instance|
    #     instance.meta_tag_description.truncate(50)
    #   end

    #   expose :kakaotalk_text do |instance|
    #     instance.meta_tag_description.truncate(100)
    #   end

    #   expose :kakaotalk_link_text do |instance|
    #     "빠띠 게시물로 이동하기"
    #   end

    #   with_options(if: lambda { |instance, options| instance.share_image_dimensions.present? }) do
    #     expose :kakaotalk_image_url do |instance|
    #       instance.meta_tag_image
    #     end
    #     expose :kakaotalk_image_width do |instance|
    #       instance.share_image_dimensions[0]
    #     end
    #     expose :kakaotalk_image_height do |instance|
    #       instance.share_image_dimensions[1]
    #     end
    #   end
    # end

    with_options(if: lambda { |instance, options| options[:sticky_comment].present? and instance.comments.exists?(id: options[:sticky_comment]) }) do
      expose :sticky_comment, using: Comment::Entity do |instance, options|
        options[:sticky_comment]
      end
    end

    expose :expired_after do |instance|
      12 * 60 * 60 * 1000
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
  belongs_to :user
  belongs_to :poll
  belongs_to :survey
  belongs_to :link_source
  belongs_to :wiki
  has_many :file_sources, dependent: :destroy, as: :file_sourceable
  has_many :messages, as: :messagable, dependent: :destroy
  has_many :decision_histories, dependent: :destroy
  has_one :post_searchable_index, dependent: :destroy, autosave: true

  belongs_to :postable, polymorphic: true
  belongs_to :last_stroked_user, class_name: User
  accepts_nested_attributes_for :link_source
  accepts_nested_attributes_for :wiki
  accepts_nested_attributes_for :file_sources, allow_destroy: true, reject_if: proc { |attributes|
    attributes['attachment'].blank? and attributes['attachment_cache'].blank? and attributes['id'].blank?
  }
  accepts_nested_attributes_for :poll
  accepts_nested_attributes_for :survey

  has_many :comments, dependent: :destroy
  has_many :readers, dependent: :destroy
  belongs_to :folder
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
  scope :previous_of_stroked, ->(post) {
    base = order_by_stroked_at
    base = base.where('posts.last_stroked_at < ?', post.last_stroked_at).where('posts.created_at < ?', post.created_at) if post.present?
    base
  }

  scope :watched_by, ->(someone) { where(issue_id: someone.member_issues) }
  scope :by_postable_type, ->(t) { where(postable_type: t.camelize) }
  scope :latest, -> { after(1.day.ago) }
  scope :not_private_blocked_of_group, ->(group, someone) {
    group ||= Group.indie
    if group.indie?
      of_searchable_issues(someone)
    else
      where(issue_id: group.issues.not_private_blocked(someone))
    end
  }
  scope :of_searchable_issues, ->(current_user = nil) {
    where(issue_id: Issue.searchable_issues(current_user))
  }
  scope :of_undiscovered_issues, ->(current_user = nil) {
    where(issue_id: Issue.undiscovered_issues(current_user))
  }
  scope :not_in_dashboard_of_group, ->(group, someone) {
    group ||= Group.indie
    where(issue_id: group.issues.not_in_dashboard(someone))
  }
  scope :having_link_or_file, -> { where.any_of(where.not(link_source: nil), where('file_sources_count > 0')) }
  scope :having_wiki, ->(status = nil) {
    condition = where.not(wiki: nil)
    condition = condition.joins('LEFT OUTER JOIN wikis on wikis.id = posts.wiki_id').where('wikis.status': status) if status.present?
    condition
  }
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

  # fulltext serch
  before_save :reindex_for_search
  # hashtagging
  before_save :reindex_hashtags

  def specific_desc
    self.parsed_title.presence || self.body.presence ||
      (ERB::Util.h(self.wiki.try(:title)).presence) ||
      (ERB::Util.h(self.poll.try(:title)).presence) ||
      (ERB::Util.h(self.file_sources.first.try(:name)).presence if self.file_sources.any?) ||
      (ERB::Util.h(self.link_source.try(:title)).presence if self.link_source.present?) ||
      (ERB::Util.h(self.wiki.try(:specific_desc)).presence if self.wiki.present?)
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

  def reviewed_by?(someone)
    return true if upvotes.exists?(user: someone)
    messagable_users.include? someone
  end

  def messagable_users
    result = [User.where(id: user)]
    result << User.where(id: comments.select(:user_id))

    if poll.present?
      result << User.where(id: poll.votings.select(:user_id))
    end

    if survey.present?
      result << User.where(id: survey.feedbacks.select(:user_id))
      result << User.where(id: survey.options.select(:user_id))
    end
    User.where.any_of(*result).where(id: Member.where(joinable: self.issue).select(:user_id))
  end

  LATEST_COMMENTS_LIMNIT_COUNT = 2
  def latest_base_comments
    return @_latest_base_comments if @_latest_base_comments.present? and comments_count == @_cached_comment_count_for_latest_base_comments
    @_cached_comment_count_for_latest_base_comments = comments_count

    result = comments.recent.after(1.weeks.ago).limit(Post::LATEST_COMMENTS_LIMNIT_COUNT)
    if last_stroked_for == 'comment' and result.empty?
      result = comments.recent.limit(1)
    end
    @_latest_base_comments = result
    @_latest_base_comments
  end

  def latest_comments
    latest_base_comments.reverse
  end

  MORE_COMMENTS_LIMNIT_COUNT = 20
  def more_comments_mode
    return @_more_comments_mode if @_more_comments_mode.present? and comments_count == @_cached_comment_count_for_more_comments_mode
    @_cached_comment_count_for_more_comments_mode = comments_count

    unless any_not_latest_comments?
      @_more_comments_mode = :empty
      return @_more_comments_mode
    end

    if too_many_today_comments?
      @_more_comments_mode = :past_day_limited
    elsif too_few_today_comments?
      buffer = Post::MORE_COMMENTS_LIMNIT_COUNT / 4
      if comments_count > Post::MORE_COMMENTS_LIMNIT_COUNT + buffer
        @_more_comments_mode = :limit
      else
        @_more_comments_mode = :all
      end
    else
      @_more_comments_mode = :past_day
    end

    @_more_comments_mode
  end

  def more_comments
    return @_more_comments if @_more_comments.present? and comments_count == @_cached_comment_count_for_more_comments
    @_cached_comment_count_for_more_comments = comments_count

    @_more_comments = case more_comments_mode
    when :empty
      Comment.none
    when :past_day
      comments.past_day
    when :past_day_limited, :limit
      comments.recent.limit(Post::MORE_COMMENTS_LIMNIT_COUNT).reverse
    when :all
      comments
    end

    return @_more_comments
  end

  def any_not_latest_comments?
    comments_count > latest_base_comments.count
  end

  def any_not_more_comments?
    comments_count > more_comments.count
  end

  def too_many_today_comments?
    buffer = Post::MORE_COMMENTS_LIMNIT_COUNT / 4
    comments.past_day.count > Post::MORE_COMMENTS_LIMNIT_COUNT + buffer
  end

  def too_few_today_comments?
    buffer = Post::MORE_COMMENTS_LIMNIT_COUNT / 4
    comments.past_day.count <= latest_base_comments.count + buffer
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

  # DEPRECATED
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
    body.present? ? "#{sanitize_html(body).truncate(15)} | #{issue.title} 빠띠" : "#{issue.title} 빠띠"
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
    readers.includes(:member).exists?('members.user_id': someone)
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
    self.last_stroked_user = someone || self.user
    self.last_stroked_for = subject
    self
  end

  def strok_by!(someone, subject)
    update_columns(last_stroked_at: DateTime.now, last_stroked_user_id: someone, last_stroked_for: subject)
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

  def last_stroked_days_from_today
    (Date.today - self.last_stroked_at.to_date).to_i
  end

  def bookmarked?(someone)
    bookmarks.exists?(user: someone)
  end

  def bookmark_by(someone)
    bookmarks.find_by(user: someone)
  end

  private

  def reindex_for_search
    self.build_post_searchable_index if self.post_searchable_index.blank?
    self.post_searchable_index.reindex if body_changed?
  end

  def reindex_hashtags(force: false)
    return if issue.private_blocked?(self.user)

    if force or self.body_changed? or (self.wiki.present? and (self.wiki.body_changed? or self.wiki.title_changed?))
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

  # DEPRECATED
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
      blockquote_index = strip_body.index('<blockquote>')
      strip_body_remain = ""
      unless blockquote_index.nil?
        strip_body_remain = strip_body.slice(blockquote_index..-1)
        strip_body = strip_body.slice(0...blockquote_index)
      end

      setences = strip_body.lines.map { |l| l.split(/(?<=<\/p>)/) }.map { |s| s.split(/(?=<br>)/) }.flatten
      if setences.any? and setences.first.length < 100
        strip_body_remain = setences[1..-1].join + strip_body_remain
        [setences.first, strip_body_remain]
      else
        [nil, body]
      end
    end
  end

  def sanitize_html text
    HTMLEntities.new.decode ::Catan::SpaceSanitizer.new.do(text)
  end
end
