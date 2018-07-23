class AddListableEvenPrivateToIssue < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :listable_even_private, :boolean, default: false
  end
end
