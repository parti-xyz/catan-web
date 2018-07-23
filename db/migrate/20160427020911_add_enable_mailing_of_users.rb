class AddEnableMailingOfUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :enable_mailing, :boolean, default: true
  end
end
