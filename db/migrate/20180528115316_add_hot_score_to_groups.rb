class AddHotScoreToGroups < ActiveRecord::Migration[4.2]
  def change
    add_column :groups, :hot_score, :integer, default: 0
    add_column :groups, :hot_score_datestamp, :string
  end
end
