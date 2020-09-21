class RemoveAnnouncingModeOfAnnouncements < ActiveRecord::Migration[5.2]
  def change
    remove_column :announcements, :announcing_mode
  end
end
