class CreateFeaturedIssues < ActiveRecord::Migration
  def change
    create_table :featured_issues do |t|
      t.string :title
      t.string :slug
      t.text :body
      t.string :image
      t.string :mobile_image
      t.string :talk_title
      t.integer :talk_id
      t.string :article_title
      t.integer :article_id
      t.string :opinion_title
      t.integer :opinion_id
      t.timestamps null: false
    end
  end
end
