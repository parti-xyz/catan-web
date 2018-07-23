class DropOpinions < ActiveRecord::Migration[4.2]
  def change
    drop_table :opinions
    drop_table :opinion_to_talks
  end
end
