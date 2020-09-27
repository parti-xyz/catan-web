class Bookmark < ApplicationRecord
  acts_as_taggable

  belongs_to :user
  belongs_to :bookmarkable, polymorphic: true

  scope :recent, -> { order(bookmarkable_created_at: :desc) }
  scope :of_group, -> (group) {
    condition = none
    all_bookmarkable_types.each do |klass|
      condition = condition.or(where(bookmarkable_type: klass.to_s).where(bookmarkable_id: klass.of_group_for_bookmark(group)))
    end
    condition
  }

  before_create :set_bookmarkable_created_at

  def self.all_bookmarkable_types
    @_poly_hash ||= [].tap do |array|
      Dir.glob(File.join(Rails.root, "app", "models", "**", "*.rb")).each do |file|
        klass = (File.basename(file, ".rb").camelize.constantize rescue nil)
        next if klass.nil? or !klass.ancestors.include?(ActiveRecord::Base)
        reflection = klass.reflect_on_association(:bookmarks)
        if reflection.present? and reflection.options[:as] == :bookmarkable
          array << klass
        end
      end
    end
    @_poly_hash
  end

  private

  def set_bookmarkable_created_at
    return if bookmarkable.blank?

    self.bookmarkable_created_at = bookmarkable.created_at
  end
end
