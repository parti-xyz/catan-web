class AddHasDecisionToPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :has_decision, :boolean, default: false

    reversible do |dir|
      dir.up do
        ActiveRecord::Base.transaction do
          Post.update_all(has_decision: false)
          Post.where.not(decision: nil).update_all(has_decision: true)
        end
      end
    end
  end
end
