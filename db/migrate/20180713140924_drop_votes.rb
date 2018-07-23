class DropVotes < ActiveRecord::Migration[4.2]
  def change
    drop_table :votes
  end
end
