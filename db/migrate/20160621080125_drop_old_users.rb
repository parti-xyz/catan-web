class DropOldUsers < ActiveRecord::Migration
  def up
    drop_table :old_users
  end

  def down
  end
end
