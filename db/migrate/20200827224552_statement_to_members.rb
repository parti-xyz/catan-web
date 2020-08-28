class StatementToMembers < ActiveRecord::Migration[5.2]
  def change
    add_column :members, :statement, :text
  end
end
