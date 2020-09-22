class Wiki < ApplicationRecord
  acts_as_paranoid
  include AutoLinkableBody

  has_one :post, dependent: :nullify
  has_one :issue, through: :post
  has_many :wiki_histories, dependent: :destroy
  belongs_to :last_wiki_history, class_name: 'WikiHistory', foreign_key: :last_wiki_history_id, optional: true
  belongs_to :last_author, class_name: "User", foreign_key: :last_author_id, optional: true
  has_many :wiki_authors, dependent: :destroy

  mount_uploader :thumbnail, PrivateFileUploader

  after_save :reserve_capture
  after_commit :capture_async
  after_create ->(obj) {
    build_history!('create') }
  after_update :build_history_after_update
  # fulltext serch
  after_save :reindex_for_search!

  attr_accessor :skip_capture, :skip_history, :reserved_capture, :conflicted_title, :conflicted_body, :continue_editing

  extend Enumerize
  enumerize :status, in: [:active, :inactive, :purge], predicates: true, scope: true

  scope :recent, -> { order(created_at: :desc) }
  scope :order_by_updated_at, -> { order(updated_at: :desc).recent }


  def last_history
    last_wiki_history
  end

  def body_striped_tags
    striped_body = body.try(:strip)
    striped_body = '' if striped_body.nil?
    sanitize_html striped_body
  end

  def capture!
    if CarrierWave.tmp_path.nil?
      Rails.logger.info "CarrierWave.tmp_pat nil!!!!"
    end

    self.skip_capture = true
    self.skip_history = true

    return if body.blank?

    begin
      self.remove_thumbnail = true
      self.save!
    rescue => ignored
    end

    max_try = 5
    curreny_try = 0

    file = nil
    begin
      curreny_try += 1

      file = Tempfile.new(["captire_wiki_#{id.to_s}", '.png'], 'tmp', :encoding => 'ascii-8bit')
      result = ApplicationController.renderer.new.render(
        partial: "wikis/capture",
        locals: { body: body }
      )
      file.write IMGKit.new(result, width: 600, quality: 10).to_png
      file.flush
      if file.respond_to? :"original_filename="
        file.original_filename = File.basename(file.path)
      end

      self.thumbnail = file
      self.save!

      file.unlink
    end while (self.read_attribute(:thumbnail).blank? and curreny_try <= max_try)

    if self.read_attribute(:thumbnail).blank?
      throw "Could not make the thumbnail : wiki #{self.id} / file #{file.try(:path)}"
    end
    self.skip_capture = false
    self.skip_history = false
  end

  def reserve_capture
    self.reserved_capture = saved_change_to_body?
  end

  def capture_async
    if !self.skip_capture and (self.read_attribute(:thumbnail).blank? or self.reserved_capture)
      WikiCaptureJob.perform_async(id)
    end
  end

  def authors
    self.wiki_authors.map(&:user)
  end

  def build_history_after_update
    return if skip_history

    if self.saved_change_to_status?
      if self.status == 'active'
        return build_history!('activate')
      elsif self.status == 'inactive'
        return build_history!('inactivate')
      elsif self.status == 'purge'
        return build_history!('purge')
      end
    end

    if self.post.saved_change_to_base_title? and !self.saved_change_to_body?
      return build_history!('update_title')
    end

    if self.saved_change_to_body? and !self.post.saved_change_to_base_title?
      return build_history!('update_body')
    end

    if self.post.saved_change_to_base_title? and self.saved_change_to_body?
      return build_history!('update_title_and_body')
    end

  end

  def build_history!(code)
    wiki_history = wiki_histories.create(title: self.post.base_title, body: body, user: last_author, wiki: self, code: code)
    wiki_authors.find_or_create_by(user: last_author)


    ActiveRecord::Base.transaction do
      if self.continue_editing && self.last_wiki_history.user == last_author
        self.last_wiki_history.destroy
      end
      self.update_column(:last_wiki_history_id, wiki_history.id)
    end
  end

  def last_activity(&block)
    return if last_history.blank?

    [last_history.activity(&block), last_history.created_at]
  end

  def conflict?
    conflicted_body.present? #or conflicted_title.present?
  end

  def active?
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

  def image_ratio
    return 0.8 if image_width == 0 or image_height == 0
    image_width / image_height.to_f
  end

  def reindex_for_search!
    post.try(:reindex_for_search!)
  end

  def build_conflict
    self.conflicted_body = self.body
    self.conflicted_title = self.post.base_title
    self.post.base_title = self.post.base_title_was
    self.body = self.body_was
  end

  def diff_conflicted_body
    self.wiki_histories.last.diff_body(self.conflicted_body)
  end

  def sanitize_html text
    HTMLEntities.new.decode ::Catan::SpaceSanitizer.new.do(text)
  end

  def too_short?
    self.body_striped_tags.try(:length) < 400
  end

  def too_long?
    self.body_striped_tags.try(:length) > 2000
  end
end
