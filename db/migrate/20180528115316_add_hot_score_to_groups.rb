class AddHotScoreToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :hot_score, :integer, default: 0
    add_column :groups, :hot_score_datestamp, :string
  end
end
