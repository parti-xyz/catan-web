class AddBodyToTalk < ActiveRecord::Migration[4.2]
  def change
    add_column :talks, :body, :text
  end
end
