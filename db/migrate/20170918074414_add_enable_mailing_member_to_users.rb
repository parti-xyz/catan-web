class AddEnableMailingMemberToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :enable_mailing_member, :boolean, default: true
  end
end
