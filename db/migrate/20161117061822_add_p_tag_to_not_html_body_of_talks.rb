class AddPTagToNotHtmlBodyOfTalks < ActiveRecord::Migration[4.2]
  include ActionView::Helpers::TextHelper
  def change
    ActiveRecord::Base.transaction do
      Talk.all.to_a.select do |talk|
        if talk.body.present? and !talk.body.start_with?('<p') and !talk.body.start_with?('<h')
          talk.update_columns(body: simple_format(talk.body))
        end
      end
    end
  end
end
