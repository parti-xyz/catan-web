class AddDecisionToPosts < ActiveRecord::Migration[4.2]
  def change
    add_column :posts, :decision, :text
  end
end
