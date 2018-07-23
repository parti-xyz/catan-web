class AddEnablePushNotificationToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :enable_push_notification, :boolean, default: true
  end
end
