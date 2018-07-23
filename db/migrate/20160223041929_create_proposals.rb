class CreateProposals < ActiveRecord::Migration[4.2]
  def change
    create_table :proposals do |t|
      t.references :discussion, null: false, index: true
      t.text :body
      t.timestamps null: false
    end
  end
end
