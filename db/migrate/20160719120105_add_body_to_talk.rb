class AddBodyToTalk < ActiveRecord::Migration
  def change
    add_column :talks, :body, :text
  end
end
