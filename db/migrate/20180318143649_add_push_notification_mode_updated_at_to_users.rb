class AddPushNotificationModeUpdatedAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :push_notification_enabled_at, :datetime
    add_column :users, :push_notification_disabled_at, :datetime
  end
end
