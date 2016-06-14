class CreateWikis < ActiveRecord::Migration
  def change
    create_table :wikis do |t|
      t.references :issue, nil: false, index: true
      t.text :body
      t.timestamps nill: false
    end
  end
end
