class Wiki < ActiveRecord::Base
  include Grape::Entity::DSL
  entity do
    include Rails.application.routes.url_helpers
    include PartiUrlHelper
    include ApiEntityHelper

    expose :id, :title, :image_ratio
    expose :thumbnail_md_url do |instance|
      instance.thumbnail.md.url
    end
    expose :authors, using: User::Entity do |instance|
      instance.authors.limit(5)
    end
    expose :latest_activity_body do |instance|
      instance.latest_activity do |user|
        if user.present?
          "<a href='#{smart_user_gallery_url(user)}'>@#{user.nickname}</a>"
        else
          I18n.t("views.user.anonymous")
        end
      end
    end
    expose :latest_activity_at do |instance|
      instance.last_history.try(:created_at)
    end
    expose :url do |instance|
      smart_wiki_url(instance)
    end
  end

  acts_as_paranoid

  has_one :post, dependent: :nullify
  has_many :wiki_histories, dependent: :destroy
  belongs_to :last_author, class_name: User, foreign_key: :last_author_id

  mount_uploader :thumbnail, PrivateFileUploader

  after_save :capture_async
  after_create ->(obj) {
    build_history('create') }
  after_update :build_history_after_update

  attr_accessor :skip_capture, :skip_history

  extend Enumerize
  enumerize :status, in: [:active, :inactive, :purge], predicates: true, scope: true

  scope :with_status, ->(status) { where(status: status) }

  def last_history
    wiki_histories.newest
  end

  def capture!
    self.skip_capture = true
    self.skip_history = true

    return if body.blank?

    self.remove_thumbnail = true
    self.save!

    file = Tempfile.new(["captire_wiki_#{id.to_s}", '.png'], 'tmp', :encoding => 'ascii-8bit')
    result = ApplicationController.renderer.new.render(
      partial: "wikis/capture",
      locals: { body: body }
    )
    file.write IMGKit.new(result, width: 600, quality: 10).to_png
    file.flush

    self.thumbnail = file
    self.save!

    file.unlink

    self.skip_capture = false
    self.skip_history = false
  end

  def capture_async
    if !self.skip_capture and (self.read_attribute(:thumbnail).blank? or body_changed?)
      WikiCaptureJob.perform_async(id)
    end
  end

  def authors
    User.where(id: wiki_histories.select(:user_id).distinct)
  end

  def build_history_after_update
    return if skip_history

    if self.status_changed?
      if self.status == 'active'
        return build_history('activate')
      elsif self.status == 'inactive'
        return build_history('inactivate')
      elsif self.status == 'purge'
        return build_history('purge')
      end
    end

    if self.title_changed? and !self.body_changed?
      return build_history('update_title')
    end

    if self.body_changed? and !self.title_changed?
      return build_history('update_body')
    end

    if self.title_changed? and self.body_changed?
      return build_history('update_title_and_body')
    end
  end

  def build_history(code)
    wiki_histories.create(title: title, body: body, user: last_author, wiki: self, code: code)
  end

  def latest_activity(&block)
    return if last_history.blank?

    last_history.activity(&block)
  end

  def latest_history
    @last_history ||= wiki_histories.order(created_at: :desc).first
  end

  def activate?
    'active' == status
  end

  def purged?
    'purge' == status
  end

  def activatable?
    %w(inactive purge).include? status
  end

  def inactivatable?
    %w(active).include? status
  end

  def purgeable?
    %w(active inactive).include? status
  end

  def specific_desc
    title
  end

  def image_ratio
    return 0.8 if image_width == 0 or image_height == 0
    image_width / image_height.to_f
  end
end



