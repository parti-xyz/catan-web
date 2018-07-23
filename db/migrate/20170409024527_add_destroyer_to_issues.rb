class AddDestroyerToIssues < ActiveRecord::Migration[4.2]
  def change
    add_reference :issues, :destroyer
  end
end
