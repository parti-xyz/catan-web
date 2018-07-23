class CreateIssues < ActiveRecord::Migration[4.2]
  def change
    create_table :issues do |t|
      t.string :title, null: false, index: true
      t.timestamps null: false
    end
  end
end
