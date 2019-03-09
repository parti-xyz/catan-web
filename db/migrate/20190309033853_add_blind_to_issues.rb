class AddBlindToIssues < ActiveRecord::Migration[5.2]
  def change
    add_reference :issues, :blinded_by, null: true
    add_column :issues, :blinded_at, :datetime
  end
end
