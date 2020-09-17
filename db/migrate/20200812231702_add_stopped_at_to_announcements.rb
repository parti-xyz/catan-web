class AddStoppedAtToAnnouncements < ActiveRecord::Migration[5.2]
  def change
    add_column :announcements, :stopped_at, :datetime
  end
end
