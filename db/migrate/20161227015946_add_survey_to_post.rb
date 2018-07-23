class AddSurveyToPost < ActiveRecord::Migration[4.2]
  def change
    add_reference :posts, :survey, index: true
  end
end
