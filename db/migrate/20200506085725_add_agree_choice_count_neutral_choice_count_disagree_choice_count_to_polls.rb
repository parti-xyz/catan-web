class AddAgreeChoiceCountNeutralChoiceCountDisagreeChoiceCountToPolls < ActiveRecord::Migration[5.2]
  def self.up
    add_column :polls, :agree_votings_count, :integer, null: false, default: 0
    add_column :polls, :neutral_votings_count, :integer, null: false, default: 0
    add_column :polls, :disagree_votings_count, :integer, null: false, default: 0
    add_column :polls, :sure_votings_count, :integer, null: false, default: 0
    Voting.counter_culture_fix_counts only: :poll, verbose: true, batch_size: 100
  end

  def self.down
    remove_column :polls, :agree_votings_count
    remove_column :polls, :neutral_votings_count
    remove_column :polls, :disagree_votings_count
    remove_column :polls, :sure_votings_count
  end
end
