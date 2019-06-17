class CreateGroupPushNotificationPreferences < ActiveRecord::Migration[5.2]
  def change
    create_table :group_push_notification_preferences do |t|
      t.references :user, null: false
      t.references :group, null: false
      t.timestamp null: false
    end

    add_index :group_push_notification_preferences, [:user_id, :group_id], unique: true, name: :group_push_notification_preferences_uk

    reversible do |dir|
      dir.up do
        ActiveRecord::Base.transaction do
          Group.all.each do |group|
            next if group.open_square? or group.slug == 'indie'
            group.member_users.each do |user|
              group.group_push_notification_preferences.build(user: user)
            end
            group.save!
          end
        end
      end
    end
  end
end
