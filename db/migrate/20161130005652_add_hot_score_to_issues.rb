class AddHotScoreToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :hot_score, :integer, default: 0
    add_column :issues, :hot_score_datestamp, :string
  end
end
