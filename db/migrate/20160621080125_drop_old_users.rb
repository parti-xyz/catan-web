class DropOldUsers < ActiveRecord::Migration[4.2]
  def up
    drop_table :old_users
  end

  def down
  end
end
