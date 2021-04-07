class User < ApplicationRecord
  include Grape::Entity::DSL
  entity do
    expose :id, :nickname, :email
    expose :imageUrl do |instance|
      instance.image.sm.url
    end

    include Rails.application.routes.url_helpers
    include PartiUrlHelper
    expose :profileUrl do |instance|
      smart_user_gallery_url(instance)
    end
  end

  acts_as_tagger
  rolify
  extend Enumerize
  enumerize :push_notification_mode, in: [:on, :no_sound, :off], predicates: true, scope: true

  include UniqueSoftDeletable
  acts_as_unique_paranoid

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable,
         :confirmable, :omniauthable, :omniauth_providers => [:facebook, :google_oauth2, :twitter]

  # validations
  VALID_NICKNAME_REGEX = /\A[ㄱ-ㅎ가-힣a-z0-9_]+\z/
  AT_NICKNAME_REGEX = /(?:^|[[:space:]])@([ㄱ-ㅎ가-힣a-z0-9_]+)/
  HTML_AT_NICKNAME_REGEX = /(?:^|[[:space:]]|>|&nbsp;)(@[ㄱ-ㅎ가-힣a-z0-9_]+)/

  validates :nickname,
    presence: true,
    exclusion: { in: %w(app new edit index session login logout users admin all crew issue group) },
    format: { with: VALID_NICKNAME_REGEX },
    uniqueness: { case_sensitive: false },
    length: { maximum: 20 }
  validate :nickname_exclude_pattern
  validates :email,
    presence: true,
    format: { with: Devise.email_regexp }, if: ->{ canceled_at.nil? }

  validates :uid, uniqueness: { scope: [:provider] }
  validates :email, uniqueness: { scope: [:provider] }, if: ->{ provider == "email" && canceled_at.nil? }
  validates :password,
    presence: true,
    confirmation: true,
    length: Devise.password_length,
    if: :password_required?

  validates_confirmation_of :password, if: :password_required?
  validates_length_of       :password, within: Devise.password_length, allow_blank: true

  # filters
  before_save :downcase_nickname
  before_save :set_uid
  before_validation :strip_whitespace, only: :nickname
  after_create :check_invitations, if: ->{ email.present? && confirmed_at.present? }

  # associations
  has_many :merged_issues, dependent: :nullify
  has_many :messages, dependent: :destroy
  has_many :send_messages, dependent: :destroy, foreign_key: :sender_id, class_name: "Message"
  has_many :posts, dependent: :destroy
  has_many :last_title_edited_posts, dependent: :nullify, foreign_key: :last_title_edited_user_id, class_name: 'Post'
  has_many :pinned_by_posts, dependent: :nullify, foreign_key: :pinned_by_id, class_name: "Post"
  has_many :comments, dependent: :destroy
  has_many :upvotes, dependent: :destroy
  has_many :votings, dependent: :destroy
  has_many :blinds, dependent: :destroy
  has_many :polls, through: :posts
  has_many :issue_organizer_members, -> { where(joinable_type: 'Issue').where(is_organizer: true) }, class_name: "Member"
  has_many :organizing_issues, through: :issue_organizer_members, source: :joinable, source_type: "Issue"
  has_many :group_organizer_members, -> { where(joinable_type: 'Group').where(is_organizer: true)}, class_name: "Member"
  has_many :organizing_groups, through: :group_organizer_members, source: :joinable, source_type: "Group"
  has_many :mentions, dependent: :destroy
  has_many :members, dependent: :destroy
  has_many :issue_members, -> { where(joinable_type: 'Issue') }, class_name: "Member"
  has_many :group_members, -> { where(joinable_type: 'Group') }, class_name: "Member"
  has_one :current_group_member,
    -> { where(joinable_type: 'Group').where(joinable_id: Current.group.try(:id)) },
    class_name: "Member"
  has_many :member_request, dependent: :destroy
  has_many :member_issues, through: :members, source: :joinable, source_type: "Issue"
  has_many :member_groups, through: :members, source: :joinable, source_type: "Group"
  has_many :device_tokens, dependent: :destroy
  has_many :invitations, dependent: :destroy
  has_many :received_invitations, dependent: :destroy, foreign_key: :recipient_id, class_name: "Invitation"
  has_many :feedbacks, dependent: :destroy
  has_many :options, dependent: :destroy
  has_many :group, dependent: :nullify
  has_many :destroyed_issues, dependent: :nullify, foreign_key: :destroyer_id, class_name: "Issue"
  has_many :summary_emails, dependent: :destroy
  has_many :last_touched_wiki, dependent: :nullify, class_name: "Wiki", foreign_key: :last_author_id
  has_many :wiki_histories, dependent: :nullify
  has_many :decision_histories, dependent: :nullify
  has_many :folders, dependent: :nullify
  has_many :bookmarks, dependent: :destroy
  has_many :beholders, dependent: :destroy
  has_many :comment_readers, dependent: :destroy
  has_many :roll_calls, dependent: :destroy
  has_many :inviting_roll_calls, dependent: :nullify, class_name: 'RollCall', foreign_key: :inviter_id
  has_many :issue_push_notification_preferences, dependent: :destroy
  has_many :group_push_notification_preferences, dependent: :destroy
  has_one :main_wiki_group, dependent: :nullify,  class_name: "Group", foreign_key: :main_wiki_post_id
  has_one :main_wiki_issue, dependent: :nullify,  class_name: "Issue", foreign_key: :main_wiki_post_id
  has_many :blinded_issues, dependent: :nullify, class_name: "Issue", foreign_key: :blinded_by_id
  has_many :blinded_groups, dependent: :nullify, class_name: "Group", foreign_key: :blinded_by_id
  belongs_to :last_visitable, polymorphic: true, optional: true
  has_many :post_readers, dependent: :destroy
  has_many :issue_readers, dependent: :destroy
  has_many :stroked_post_users, dependent: :destroy
  has_many :wiki_authors, dependent: :destroy
  has_many :comment_authors, dependent: :destroy
  has_many :group_observations, dependent: :destroy, class_name: 'MessageConfiguration::GroupObservation'
  has_many :issue_observations, dependent: :destroy, class_name: 'MessageConfiguration::IssueObservation'
  has_many :post_observations, dependent: :destroy, class_name: 'MessageConfiguration::PostObservation'

  ## uploaders
  # mount
  mount_uploader :image, UserImageUploader

  # scopes
  scope :latest, -> { after(1.day.ago) }
  scope :recent, -> { order(created_at: :desc) }
  scope :previous_of_recent, ->(user) {
    base = recent
    base = base.where('users.created_at < ?', user.created_at) if user.present?
    base
  }
  scope :not_canceled, -> { where(canceled_at: nil) }

  scope :with_optional_group_observations, ->(group) {
    joins("
      LEFT OUTER JOIN group_observations
      ON group_observations.user_id = users.id
      AND
        (
          group_observations.group_id = #{group.id}
          OR
          group_observations.group_id IS NULL
        )
    ")
  }

  scope :with_optional_issue_observations, ->(issue) {
    joins("
      LEFT OUTER JOIN issue_observations
      ON issue_observations.user_id = users.id
      AND
        (
          issue_observations.issue_id = #{issue.id}
          OR
          issue_observations.issue_id IS NULL
        )
    ")
  }

  scope :with_optional_post_observations, ->(post) {
    joins("
      LEFT OUTER JOIN post_observations
      ON post_observations.user_id = users.id
      AND
        (
          post_observations.post_id = #{post.id}
          OR
          post_observations.post_id IS NULL
        )
    ")
  }

  scope :observing_message, -> (messagable, action, payoffs) {
    group = messagable.group_for_message
    base_users = where(id: group.members.select(:user_id))

    if group.frontable?
      default_observable = MessageConfiguration::RootObservation.of(group).observable?(action, payoffs)

      if MessageObservationConfigurable::ACTIONS_PER_POST.include?(action)
        post = messagable.post_for_message
        issue = messagable.issue_for_message
        base_users
          .with_optional_group_observations(group)
          .with_optional_issue_observations(issue)
          .with_optional_post_observations(post)
          ._condition_observing(action, payoffs, default_observable)
      elsif MessageObservationConfigurable::ACTIONS_PER_ISSUE.include?(action)
        issue = messagable.issue_for_message
        base_users
          .with_optional_group_observations(group)
          .with_optional_issue_observations(issue)
          ._condition_observing(action, payoffs, default_observable)
      elsif MessageObservationConfigurable::ACTIONS_PER_GROUP.include?(action)
        base_users
          .with_optional_group_observations(group)
          .send(:"_condition_observing", action, payoffs, default_observable)
      else
        User.all
      end
    else
      if payoffs == MessageObservationConfigurable.all_app_push_payoffs
        base_users = base_users.where(push_notification_mode: ['on', 'no_sound'])
      elsif payoffs == MessageObservationConfigurable.all_subscribing_payoffs
      else
        abort "Not allowed payoffs #{payoffs.inspect}"
      end

      issue = messagable.issue_for_message

      # 그룹 알림을 받는 해당 그룹 멤버
      group_base_users = base_users.where(id: GroupPushNotificationPreference.where(group: group).select(:user_id))
      # 채널 알림 모드가 highlight인 해당 채널의 멤버
      # 기본 채널 알림 모드는 detail
      issue_base_users = issue.present? ?
        base_users.where(id: issue.member_users)
          .joins("LEFT OUTER JOIN issue_push_notification_preferences
            ON `issue_push_notification_preferences`.`user_id` = `users`.`id`
            AND `issue_push_notification_preferences`.`issue_id` = #{issue.id}")
          .where("issue_push_notification_preferences.value <> 'nothing' OR issue_push_notification_preferences.value IS NULL")
        : User.none

      case action.to_sym
      when :create_issue
        group_base_users
      when :mention, :upvote, :update_issue_title
        issue_base_users
      when :create_comment, :closed_survey
        post = messagable.post_for_message
        # 이 게시물에 메시지를 받은 적이 있거나 상세모드 일 때
        issue_base_users.where(id: post.messages.select(:user_id)).or(issue_base_users.where('issue_push_notification_preferences.value': ['detail', nil]))
      when :pin_post, :create_post
        issue_base_users.where('issue_push_notification_preferences.value': ['compact', 'detail', nil])
      else
        User.all
      end
    end
  }

  scope :"_condition_observing", ->(action, payoffs, default_observable) {
    if MessageObservationConfigurable::ACTIONS_PER_POST.include?(action)
      where("post_observations.payoff_#{action}": payoffs)
      .or(
        where("post_observations.payoff_#{action}": nil)
        .where("issue_observations.payoff_#{action}": payoffs)
      )
      .or(
        where("post_observations.payoff_#{action}": nil)
        .where("issue_observations.payoff_#{action}": nil)
        .where("group_observations.payoff_#{action}": payoffs)
      )
      .or(
        where("post_observations.payoff_#{action}": nil)
        .where("issue_observations.payoff_#{action}": nil)
        .where("group_observations.payoff_#{action}": nil)
        .where('true = ?', default_observable)
      )
    elsif MessageObservationConfigurable::ACTIONS_PER_ISSUE.include?(action)
      where("issue_observations.payoff_#{action}": payoffs)
        .or(
          where("issue_observations.payoff_#{action}": nil)
          .where("group_observations.payoff_#{action}": payoffs)
        )
        .or(
          where("issue_observations.payoff_#{action}": nil)
          .where("group_observations.payoff_#{action}": nil)
          .where('true = ?', default_observable)
        )
    elsif MessageObservationConfigurable::ACTIONS_PER_GROUP.include?(action)
      where("group_observations.payoff_#{action}": payoffs)
        .or(
          where("group_observations.payoff_#{action}": nil)
          .where('true = ?', default_observable)
        )
    else
      none
    end
  }

  def admin?
    @__cache_admin ||= has_role?(:admin)
  end

  # devise

  def self.find_or_initialize_with_errors(required_attributes, attributes, error=:invalid)
    result = super
    return result if result.blank?

    result.touch_group_slug = attributes[:touch_group_slug] if attributes.key?(:touch_group_slug)
    result
  end

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  def self.parse_omniauth(data)
    {provider: data['provider'], uid: data['uid'], email: data['info']['email'], image: data['info']['image']}
  end

  def self.find_for_omniauth(auth)
    where(provider: auth[:provider], uid: auth[:uid]).first
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    email = conditions.delete(:email)
    where(conditions.to_h).where(["provider = 'email' AND uid = :value", { :value => email.downcase }]).first
  end

  def self.new_with_session(params, session)
    resource = super
    auth = session["devise.omniauth_data"]
    if auth.present?
      auth["email"] = params['email'] if params['email'].present?
      resource.assign_attributes(auth)
      resource.password = Devise.friendly_token[0,20]
      resource.confirmed_at = DateTime.now
      resource.remote_image_url = auth['image']
    else
      resource.provider = 'email'
    end
    resource
  end

  def self.create_by_external_auth!(external_auth, nickname, email)
    User.create! uid: external_auth.uid,
      provider: external_auth.provider,
      email: (external_auth.email || email),
      password: Devise.friendly_token[0,20],
      confirmed_at: DateTime.now,
      enable_mailing_summary: true,
      push_notification_mode: :on,
      nickname: nickname,
      remote_image_url: external_auth.image_url
  end

  def writing_counts
    counts = OpenStruct.new
    counts.groups_count = member_groups.count
    counts.posts_count = posts.count
    counts.comments_count = comments.count
    counts
  end

  def need_to_more_member?(group = nil)
    member_issues.displayable_in_current_group(group).alive.empty?
  end

  def hottest_posts(count)
    posts.hottest.limit(count)
  end

  def is_organizer?(joinable)
    joinable.organized_by?(self)
  end

  def cache_member
    @cacheable_members = true
  end

  def cached_group_member(group)
    return unless @cacheable_members
    if @cached_group_members.blank?
      @cached_group_members = self.group_members.to_a.map do |group_member|
        [group_member.joinable_id, group_member]
      end.to_h
    end

    @cached_group_members[group.id]
  end

  def smart_issue_member(issue)
    return if issue.blank?
    (self.cached_channel_member(issue) || self.members.find_by(joinable: issue))
  end

  def smart_group_member(group)
    return if group.blank?
    (self.cached_group_member(group) || self.members.find_by(joinable: group))
  end

  def cached_channel_member(parti)
    return unless @cacheable_members
    if @cached_channel_members.blank?
      @cached_channel_members = self.issue_members.includes(:joinable).to_a.map do |parti_member|
        [parti_member.joinable_id, parti_member]
      end.to_h
    end

    @cached_channel_members[parti.try(:id)]
  end

  def only_all_member_issues
    member_issues.where.not(id: issue_organizer_members.select(:joinable_id))
  end

  def watched_posts(group = nil)
    Post.where(issue: member_issues.displayable_in_current_group(group).alive)
  end

  def watched_comments(group = nil)
    Comment.where(post: watched_posts(group))
  end

  def mentionable? someone
    return false if someone.blank?
    return false if someone == self
    return true
  end

  def slug
    nickname.try(:ascii_only?) ? nickname : "~#{id}"
  end

  def self.slug_to_id(slug)
    return nil unless slug[0] == '~'
    Integer(slug[1..-1]) rescue nil
  end

  def sent_new_posts_email_today!
    update_attributes(sent_new_posts_email_at: Date.today)
  end

  def sent_new_posts_email_today?
    sent_new_posts_email_at.present? and sent_new_posts_email_at >= Date.today
  end

  def after_confirmation
    check_invitations
  end

  def current_device_tokens
    application_ids = { 'production' => %w(xyz.parti.catan.ios xyz.parti.catan.android), 'development' => %w(xyz.parti.catan.ios.debug xyz.parti.catan.android.debug) }[Rails.env]
    return [] if application_ids.blank?

    device_tokens.where(application_id: application_ids)
  end

  def important_messages_count(group = nil)
    result = messages.unread
    result = result.where('created_at > ?', self.messages_read_at || 0).where('created_at > ?', 2.day.ago)
    result = result.of_group(group) if group.present?
    @_cached_important_messages_count = result.count

    @_cached_important_messages_count
  end

  def cached_important_messages_count(group = nil)
    if @_cached_important_messages_count.blank?
      important_messages_count(group)
    end
    @_cached_important_messages_count
  end

  def important_mention_messages_count(group = nil)
    result = messages.unread.where(action: 'mention')
    result = result.where('created_at > ?', self.messages_read_at).where('created_at > ?', 2.day.ago)
    result = result.of_group(group) if group.present?
    @_cached_important_mention_messages_count = result.count

    @_cached_important_mention_messages_count
  end

  def cached_important_mention_messages_count(group = nil)
    if @_cached_important_mention_messages_count.blank?
      important_mention_messages_count(group)
    end
    @_cached_important_mention_messages_count
  end

  def important_not_mention_messages_count(group = nil)
    result = messages.unread.where.not(action: 'mention')
    result = result.where('created_at > ?', self.messages_read_at).where('created_at > ?', 2.day.ago)
    result = result.of_group(group) if group.present?
    @_cached_important_not_mention_messages_count = result.count

    @_cached_important_not_mention_messages_count
  end

  def cached_important_not_mention_messages_count(group = nil)
    if @_cached_important_not_mention_messages_count.blank?
      important_not_mention_messages_count(group)
    end
    @_cached_important_not_mention_messages_count
  end

  # summary emails
  def self.need_to_delivery(code)
    joins("LEFT OUTER JOIN summary_emails se ON users.id = se.user_id")
    .where("se.id is null or se.mailed_at <= ?", SummaryEmail.limit_datetime(code))
    .order("se.mailed_at")
  end

  def need_to_delivery?(code)
    !summary_emails.where("mailed_at > ?", SummaryEmail.limit_datetime(code)).exists?(code)
  end

  def mail_delivered!(code)
    m = summary_emails.find_or_initialize_by(code: code)
    m.mailed_at = DateTime.now
    m.save!
  end

  def pinned_posts
    watched_posts.pinned.order('pinned_at desc')
  end

  def unbehold_pinned_posts(group = nil)
    result = pinned_posts.where.not(id: self.beholders.select(:post_id))
    result = result.of_group(group) if group.present?
    result
  end

  def latest_posted_issues(count)
    return [] if self.member_issues.count < count * 1.5
    latest_issue_ids = self.posts.recent.limit(10).to_a.group_by(&:issue_id).map(&:first)
    Issue.where(id: latest_issue_ids).postable(self)
  end

  def enable_push_notification?
    User.enable_push_notification?(self.push_notification_mode)
  end

  def pushable_notification?(message)
    return false unless enable_push_notification?

    result = IssuePushNotificationPreference.pushable_notification?(self, message)
    result || true
  end

  def self.enable_push_notification?(push_notification_mode)
    %i(on no_sound).include? push_notification_mode.to_sym
  end

  def self.parse_nicknames nicknames
    return [] if nicknames.blank?
    (nicknames.split(",") || []).map(&:strip).uniq.compact.map do |nickname|
      self.find_by(nickname: nickname)
    end.compact
  end

  def issue_push_notification_preference_text(issue)
    I18n.t("enumerize.issue_push_notification_preference.value_issue_header.#{issue_push_notification_preference_value(issue)}")
  end

  def issue_push_notification_preference_value(issue)
    issue_push_notification_preference = issue_push_notification_preferences.find_by(issue: issue)
    (issue_push_notification_preference.try(:value) || (issue&.group&.frontable? ? 'highlight' : 'detail')).to_s
  end

  def canceled?
    self.canceled_at.present?
  end

  private

  def downcase_nickname
    self.nickname = nickname.downcase
  end

  def set_uid
    self.uid = self.email if self.provider == 'email' && canceled_at.nil?
  end

  def check_invitations
    ActiveRecord::Base.transaction do
      invitations = Invitation.where(recipient_email: self.email)
      invitations.each do |invitation|
        if invitation.joinable_type == 'Issue'
          member = MemberIssueService.new(issue: invitation.joinable, user: self, is_force: true).call

          if member.try(:persisted?)
            SendMessage.run(source: member, sender: invitation.user, action: :admit_issue_member)
          end
        elsif invitation.joinable_type == 'Group'
          member = MemberGroupService.new(group: invitation.joinable, user: self).call

          if member.try(:persisted?)
            SendMessage.run(source: member, sender: invitation.user, action: :admit_group_member)
          end
        end
      end
      invitations.destroy_all
    end
  end

  def nickname_exclude_pattern
    if (self.nickname =~ /\Aparti.*\z/i) and (self.nickname_was !~ /\Aparti.*\z/i)
      errors.add(:nickname, I18n.t('errors.messages.taken'))
    end
  end

  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end

  def strip_whitespace
    self.nickname = self.nickname.strip unless self.nickname.nil?
  end
end
