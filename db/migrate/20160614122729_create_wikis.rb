class CreateWikis < ActiveRecord::Migration[4.2]
  def change
    create_table :wikis do |t|
      t.references :issue, nil: false, index: true
      t.text :body, limit: 160.megabytes - 1
      t.timestamps nill: false
    end
  end
end
