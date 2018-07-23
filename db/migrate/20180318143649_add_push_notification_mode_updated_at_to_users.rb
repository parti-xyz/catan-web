class AddPushNotificationModeUpdatedAtToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :push_notification_enabled_at, :datetime
    add_column :users, :push_notification_disabled_at, :datetime
  end
end
