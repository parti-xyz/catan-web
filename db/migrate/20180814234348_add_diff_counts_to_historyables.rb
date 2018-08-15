class AddDiffCountsToHistoryables < ActiveRecord::Migration[5.2]
  def change
    add_column :decision_histories, :diff_body_adds_count, :integer, default: 0
    add_column :decision_histories, :diff_body_removes_count, :integer, default: 0
    add_column :wiki_histories, :diff_body_adds_count, :integer, default: 0
    add_column :wiki_histories, :diff_body_removes_count, :integer, default: 0

    reversible do |dir|
      dir.up do
        transaction do
          DecisionHistory.all.each do |history|
            history.build_diff_body_count
            history.save!
          end
          WikiHistory.all.each do |history|
            history.build_diff_body_count
            history.save!
          end
        end
      end
    end
  end
end
