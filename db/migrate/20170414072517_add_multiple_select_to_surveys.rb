class AddMultipleSelectToSurveys < ActiveRecord::Migration[4.2]
  def change
    add_column :surveys, :multiple_select, :boolean, default: false
  end
end
