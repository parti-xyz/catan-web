class DropProposals < ActiveRecord::Migration[4.2]
  def change
    drop_table :proposals
  end
end
