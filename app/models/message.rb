class Message < ApplicationRecord
  belongs_to :user
  belongs_to :sender, class_name: 'User'
  belongs_to :messagable, -> { try(:with_deleted) || all }, polymorphic: true
  belongs_to :cluster_owner, polymorphic: true, optional: true

  scope :recent, -> { order(id: :desc) }
  scope :latest, -> { after(1.day.ago) }
  scope :only_upvote, -> { where(messagable_type: Upvote.to_s) }
  scope :of_group, -> (group) { where(group_slug: group.slug) }
  scope :depreated_of_group, -> (group) {
    condition = none
    all_messagable_types.each do |klass|
      condition = condition.or(where(messagable_type: klass.to_s).where(messagable_id: klass.of_group_for_message(group)))
    end
    condition
  }
  scope :of_issue, -> (issue) {
    condition = none
    all_messagable_types.each do |klass|
      condition = condition.or(where(messagable_type: klass.to_s).where(messagable_id: klass.of_issue_for_message(issue)))
    end
    condition
  }
  scope :unread, -> { where(read_at: nil) }

  before_save :setup_group_slug

  def post
    messagable.try(:post_for_message)
  end

  def issue
    messagable.issue_for_message
  end

  def group
    messagable.group_for_message
  end

  def action_params_hash
    JSON.parse(action_params)
  end

  def unread?
    read_at.blank?
  end

  def fcm_pushable?
    self.user.pushable_notification?(self)
  end

  def self.cluster_messages(messages, need_to_read_only, page, per, limit = nil)
    clusters = messages.page(page).per(per)
      .select(:cluster_owner_id, :cluster_owner_type)
      .group(:cluster_owner_id, :cluster_owner_type)
      .select('MAX(id) AS max_clustered_message_id')
      .reorder('').order('max_clustered_message_id desc')
      .select(need_to_read_only ? 'SUM(IF(read_at IS NULL, 1, 0)) AS messages_count' : 'COUNT(id) AS messages_count')
      .having('messages_count > 0')
      .select('SUM(IF(read_at IS NULL, 1, 0)) AS unread_messages_count')

    clusters = if need_to_read_only
      clusters.select("GROUP_CONCAT(IF(read_at IS NULL, id, NULL) ORDER BY created_at DESC SEPARATOR ',')
        AS all_clustered_message_id")
    else
      clusters.select("GROUP_CONCAT(id ORDER BY created_at DESC SEPARATOR ',')
        AS all_clustered_message_id")
    end

    base_messages = messages
    if need_to_read_only
      base_messages = base_messages.unread
    end

    cluster_array = clusters.to_a
    page_array = base_messages
      .reorder('').recent
      .includes(:user, :sender, :messagable, :cluster_owner)
      .where(cluster_owner: cluster_array.map(&:cluster_owner))
      .where(id: cluster_array.map do |cluster|
        result = cluster.all_clustered_message_id
        result = result.split(',').compact
        result = result.first(limit) if limit.present?
        result
      end.flatten)
      .to_a
      .group_by(&:cluster_owner)
      .transform_keys do |cluster_owner|
        cluster_array.detect do |cluster|
          cluster.cluster_owner == cluster_owner
        end
      end
      .sort do |(a_cluster, _), (b_cluster, _)|
        b_cluster.max_clustered_message_id <=> a_cluster.max_clustered_message_id
      end

    Kaminari.paginate_array(page_array, total_count: clusters.total_count).page(page).per(per)
  end

  def self.all_messagable_types
    @_poly_hash ||= [].tap do |array|
      Dir.glob(File.join(Rails.root, "app", "models", "**", "*.rb")).each do |file|
        klass = (File.basename(file, ".rb").camelize.constantize rescue nil)
        next if klass.nil? or !klass.ancestors.include?(ActiveRecord::Base)
        reflection = klass.reflect_on_association(:messages)
        if reflection.present? and reflection.options[:as] == :messagable
          array << klass
        end
      end
    end
    @_poly_hash
  end

  private

  def setup_group_slug
    self.group_slug = group_for_message&.slug
  end
end
