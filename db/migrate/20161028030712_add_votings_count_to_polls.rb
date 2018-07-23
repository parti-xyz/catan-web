class AddVotingsCountToPolls < ActiveRecord::Migration[4.2]
  def change
    add_column :polls, :votings_count, :integer, default: 0
  end
end
