class ModifyPushNotificationModeOfUsers < ActiveRecord::Migration
  def change
    add_column :users, :push_notification_mode, :string, default: 'on'

    reversible do |dir|
      dir.up do
        query = "UPDATE users SET push_notification_mode = 'off'"
        ActiveRecord::Base.connection.execute query
        say query

        query = "UPDATE users SET push_notification_mode = 'on' where enable_push_notification = '1'"
        ActiveRecord::Base.connection.execute query
        say query
      end
    end

    remove_column :users, :enable_push_notification
  end
end
