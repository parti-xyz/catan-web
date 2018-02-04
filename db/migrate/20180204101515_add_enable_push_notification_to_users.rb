class AddEnablePushNotificationToUsers < ActiveRecord::Migration
  def change
    add_column :users, :enable_push_notification, :boolean, default: true
  end
end
