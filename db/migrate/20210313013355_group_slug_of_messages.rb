class GroupSlugOfMessages < ActiveRecord::Migration[5.2]

  class Message < ApplicationRecord
    belongs_to :messagable, -> { try(:with_deleted) || all }, polymorphic: true

    scope :depreated_of_group, -> (group) {
      condition = none
      all_messagable_types.each do |klass|
        condition = condition.or(where(messagable_type: klass.to_s).where(messagable_id: klass.of_group_for_message(group)))
      end
      condition
    }

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

  class Group < ApplicationRecord
    has_many :issues, dependent: :restrict_with_error, primary_key: :slug, foreign_key: :group_slug
  end

  def change
    # add_column :messages, :group_slug, :string

    reversible do |dir|
      dir.up do
        # Message.before(1.month.ago).delete_all

        group_count = Group.count
        Group.all.each_with_index do |group, index|
          Message.depreated_of_group(group).update_all(group_slug: group.slug)
          STDOUT.write("\rGroups processed : #{index + 1} / #{group_count}")
          STDOUT.flush
        end
      end
    end
  end
end
