module UniqueSoftDeletable
  extend ActiveSupport::Concern

  included do
    def paranoia_restore_attributes
      {
        deleted_at: nil,
        active: 'on'
      }
    end

    def paranoia_destroy_attributes
      {
        deleted_at: current_time_from_proper_timezone,
        active: nil
      }
    end
  end

  class_methods do
    def acts_as_unique_paranoid
      acts_as_paranoid column: :active, column_type: :string, sentinel_value: 'on'
    end
  end
end
