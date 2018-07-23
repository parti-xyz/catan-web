class AddHiddenOptionVotersToSurveys < ActiveRecord::Migration[4.2]
  def change
    add_column :surveys, :hidden_option_voters, :boolean, default: false
  end
end
