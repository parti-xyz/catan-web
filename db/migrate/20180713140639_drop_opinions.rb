class DropOpinions < ActiveRecord::Migration
  def change
    drop_table :opinions
    drop_table :opinion_to_talks
  end
end
