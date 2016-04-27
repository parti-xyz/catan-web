class AddEnableMailingOfUsers < ActiveRecord::Migration
  def change
    add_column :users, :enable_mailing, :boolean, default: true
  end
end
