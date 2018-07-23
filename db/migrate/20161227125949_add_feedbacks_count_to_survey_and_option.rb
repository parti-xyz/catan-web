class AddFeedbacksCountToSurveyAndOption < ActiveRecord::Migration[4.2]
  def change
    add_column :surveys, :feedbacks_count, :integer, default: 0
    add_column :options, :feedbacks_count, :integer, default: 0

    reversible do |dir|
      dir.up do
        Survey.pluck(:id).map { |id| Survey.reset_counters(id, :feedbacks) }
        Option.pluck(:id).map { |id| Option.reset_counters(id, :feedbacks) }
      end
    end
  end
end
