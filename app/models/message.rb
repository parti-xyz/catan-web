class Message < ApplicationRecord
  belongs_to :user
  belongs_to :sender, class_name: "User"
  belongs_to :messagable, -> { try(:with_deleted) || all }, polymorphic: true

  scope :recent, -> { order(id: :desc) }
  scope :latest, -> { after(1.day.ago) }
  scope :only_upvote, -> { where(messagable_type: Upvote.to_s) }
  scope :of_group, -> (group) {
    condition = none
    all_messagable_types.each do |klass|
      condition = condition.or(where(messagable_type: klass.to_s).where(messagable_id: klass.send(klass.send(:messagable_group_method), group)))
    end
    condition
  }
  scope :unread, -> { where(read_at: nil) }

  def post
    messagable.try(:post)
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
