class AddDecisionToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :decision, :text
  end
end
