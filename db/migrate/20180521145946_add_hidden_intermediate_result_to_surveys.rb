class AddHiddenIntermediateResultToSurveys < ActiveRecord::Migration[4.2]
  def change
    add_column :surveys, :hidden_intermediate_result, :boolean, default: false
  end
end
