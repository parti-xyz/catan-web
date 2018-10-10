class CreateIssuePushNotificationPreferences < ActiveRecord::Migration[5.2]
  def change
    create_table :issue_push_notification_preferences do |t|
      t.references :user, null: false
      t.references :issue, null: false
      t.string :value, null: false
      t.timestamp null: false
    end

    add_index :issue_push_notification_preferences, [:user_id, :issue_id], unique: true, name: :issue_push_notification_preferences_uk
  end
end
