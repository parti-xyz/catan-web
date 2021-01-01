class AddIsDecisionToComment < ActiveRecord::Migration[5.2]
  def change
    add_column :comments, :is_decision, :boolean, default: false
  end
end
