class DropTalksAgain < ActiveRecord::Migration[4.2]
  def change
    drop_table :talks
  end
end
