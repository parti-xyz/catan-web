class AddHiddenIntermediateResultToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :hidden_intermediate_result, :boolean, default: false
  end
end
