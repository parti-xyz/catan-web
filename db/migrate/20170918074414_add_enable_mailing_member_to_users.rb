class AddEnableMailingMemberToUsers < ActiveRecord::Migration
  def change
    add_column :users, :enable_mailing_member, :boolean, default: true
  end
end
