class AddVotingsCountToPolls < ActiveRecord::Migration
  def change
    add_column :polls, :votings_count, :integer, default: 0
  end
end
