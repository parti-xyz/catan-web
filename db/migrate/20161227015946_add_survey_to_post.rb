class AddSurveyToPost < ActiveRecord::Migration
  def change
    add_reference :posts, :survey, index: true
  end
end
