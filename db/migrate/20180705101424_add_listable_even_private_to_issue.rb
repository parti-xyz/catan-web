class AddListableEvenPrivateToIssue < ActiveRecord::Migration
  def change
    add_column :issues, :listable_even_private, :boolean, default: false
  end
end
