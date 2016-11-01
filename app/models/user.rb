class User < ActiveRecord::Base
  include Grape::Entity::DSL
  entity :id, :nickname, :email do
    expose :image, as: :image_url do |model|
      model.image.sm.url
    end
  end

  include UniqueSoftDeletable
  acts_as_unique_paranoid

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable,
         :confirmable, :omniauthable, :omniauth_providers => [:facebook, :google_oauth2, :twitter]

  # validations
  VALID_NICKNAME_REGEX = /\A[ㄱ-ㅎ가-힣a-z0-9_]+\z/i
  AT_NICKNAME_REGEX = /(?:^|\s)@([ㄱ-ㅎ가-힣a-z0-9_]+)/
  HTML_AT_NICKNAME_REGEX = /(?:^|\s|>)(@[ㄱ-ㅎ가-힣a-z0-9_]+)/

  validates :nickname,
    presence: true,
    exclusion: { in: %w(app new edit index session login logout users admin all crew issue group) },
    format: { with: VALID_NICKNAME_REGEX },
    uniqueness: { case_sensitive: false },
    length: { maximum: 20 }
  validate :nickname_exclude_pattern
  validates :email,
    presence: true,
    format: { with: Devise.email_regexp }

  validates :uid, uniqueness: {scope: [:provider]}
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
  after_create :watch_default_issues

  # associations
  has_many :messages
  has_many :posts
  has_many :talks, through: :posts, source: :postable, source_type: Talk
  has_many :comments
  has_many :upvotes
  has_many :votes
  has_many :polls, through: :talks
  has_many :watches
  has_many :watched_issues, through: :watches, source: :issue
  has_many :makers
  has_many :making_issues, through: :makers, source: :issue
  has_many :member
  has_many :member_issues, through: :member, source: :issue

  ## uploaders
  # mount
  mount_uploader :image, UserImageUploader

  # scopes
  scope :latest, -> { after(1.day.ago) }
  scope :recent, -> { order(created_at: :desc) }


  def admin?
    if Rails.env.staging? or Rails.env.production?
      %w(account@parti.xyz pinkcrimson@gmail.com jennybe0117@gmail.com rest515@parti.xyz berry@parti.xyz royjung@parti.xyz mozolady@gmail.com dalikim@parti.xyz lulu@parti.xyz qus1225@gmail.com dmtgjh@naver.com).include? email
    else
      %w(account@parti.xyz admin@test.com foroso@gmail.com).include? email
    end
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

  def self.create_by_external_auth!(external_auth, nickname)
    User.create! uid: external_auth.uid,
      provider: external_auth.provider,
      email: external_auth.email,
      password: Devise.friendly_token[0,20],
      confirmed_at: DateTime.now,
      enable_mailing: true,
      nickname: nickname,
      remote_image_url: external_auth.image_url
  end

  def watched_counts
    counts = OpenStruct.new
    counts.comments_count = watched_posts.sum(:comments_count)
    counts.latest_comments_count = watched_comments.latest.count
    counts.talks_count = watched_talks.count
    counts.latest_talks_count = watched_talks.latest.count
    counts
  end

  def writing_counts(issue = nil)
    counts = OpenStruct.new
    unless issue.present?
      counts.parties_count = watches.count
      counts.polls_count = polls.count
      counts.latest_polls_count = polls.latest.count
      counts.talks_count = talks.count
      counts.latest_talks_count = talks.latest.count
    else
      counts.comments_count = comments.by_issue(issue).count
      counts.latest_comments_count = comments.by_issue(issue).latest.count
      counts.upvotes_count = upvotes.by_issue(issue).count
      counts.latest_upvotes_count = upvotes.by_issue(issue).latest.count
      counts.polls_count = polls.by_issue(issue).count
      counts.latest_polls_count = polls.by_issue(issue).latest.count
    end
    counts
  end

  def need_to_more_watch_or_member?(group = nil)
    watched_issues.only_group_or_all_if_blank(group).empty?
  end

  def hottest_posts(count)
    posts.hottest.limit(count)
  end

  def maker?(issue)
    makers.exists?(issue: issue)
  end

  def only_watched_issues
    watched_issues.where.not(id: makers.select(:issue_id))
  end

  def only_watched_or_member_issues(group)
    if group.try(:membership?)
      member_issues.only_group(group).where.not(id: makers.select(:issue_id))
    else
      watched_issues.only_group(group).where.not(id: makers.select(:issue_id))
    end
  end

  def watched_posts(group = nil)
    Post.where(issue: watched_issues.only_group_or_all_if_blank(group))
  end

  def watched_talks
    watched_posts.only_talks
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

  private

  def downcase_nickname
    self.nickname = nickname.downcase
  end

  def set_uid
    self.uid = self.email if self.provider == 'email'
  end

  def watch_default_issues
    issue = Issue.find_by slug: Issue::SLUG_OF_PARTI_PARTI, group_slug: nil
    Watch.create(user: self, issue: issue) if issue.present?
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
