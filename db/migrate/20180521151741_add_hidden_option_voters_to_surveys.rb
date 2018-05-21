class AddHiddenOptionVotersToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :hidden_option_voters, :boolean, default: false
  end
end
