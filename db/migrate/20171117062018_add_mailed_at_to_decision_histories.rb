class AddMailedAtToDecisionHistories < ActiveRecord::Migration[4.2]
  def change
    add_column :decision_histories, :mailed_at, :datetime
    DecisionHistory.update_all(mailed_at: DateTime.now)
  end
end
