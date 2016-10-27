class AddHasPollToTalks < ActiveRecord::Migration
  def change
    add_column :talks, :has_poll, :boolean, default: false
  end
end
