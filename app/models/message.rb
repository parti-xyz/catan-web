class Message < ApplicationRecord
  belongs_to :user
  belongs_to :sender, class_name: 'User'
  belongs_to :messagable, -> { try(:with_deleted) || all }, polymorphic: true
  belongs_to :cluster_owner, polymorphic: true, optional: true

  scope :recent, -> { order(id: :desc) }
  scope :latest, -> { after(1.day.ago) }
  scope :only_upvote, -> { where(messagable_type: Upvote.to_s) }
  scope :of_group, -> (group) {
    condition = none
    all_messagable_types.each do |klass|
      condition = condition.or(where(messagable_type: klass.to_s).where(messagable_id: klass.of_group_for_message(group)))
    end
    condition
  }
  scope :unread, -> { where(read_at: nil) }

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

  def self.cluster_messages(messages, need_to_read_only, page, per)
    cluster_owners = messages.group(:cluster_owner_id, :cluster_owner_type)
      .select(:cluster_owner_id, :cluster_owner_type,
        'MAX(id) AS max_clustered_message_id')
      .reorder('').order('max_clustered_message_id desc')
      .page(page).per(per)

    if need_to_read_only
      cluster_owners = cluster_owners
        .select('SUM(if(read_at IS NULL, 1, 0)) AS unreads_count')
        .having('unreads_count > 0')
    end

    base_messages = messages
    if need_to_read_only
      base_messages = base_messages.unread
    end

    cluster_owners_array = cluster_owners.to_a
    cluster_messages = base_messages
      .reorder('').recent
      .includes(:user, :sender, :messagable, :cluster_owner)
      .where(cluster_owner: cluster_owners_array.map(&:cluster_owner))
      .to_a
      .group_by(&:cluster_owner)
      .sort do |cluster_owner, _|
        cluster_owners_array.first do |current_cluster_owner|
          current_cluster_owner.cluster_owner == cluster_owner
        end&.max_clustered_message_id
      end.to_h

    [cluster_owners, cluster_messages]
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
end
