class AddDurationToSurveys < ActiveRecord::Migration[4.2]
  def change
    add_column :surveys, :duration, :integer, default: 0
  end
end
