class AddChoiceToComments < ActiveRecord::Migration[4.2]
  def change
    add_column :comments, :choice, :string
  end
end
