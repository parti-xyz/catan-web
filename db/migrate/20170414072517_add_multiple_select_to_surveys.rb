class AddMultipleSelectToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :multiple_select, :boolean, default: false
  end
end
