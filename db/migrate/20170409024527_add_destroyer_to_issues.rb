class AddDestroyerToIssues < ActiveRecord::Migration
  def change
    add_reference :issues, :destroyer
  end
end
