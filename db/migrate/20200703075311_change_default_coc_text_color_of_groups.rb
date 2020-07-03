class ChangeDefaultCocTextColorOfGroups < ActiveRecord::Migration[5.2]
  def change
    change_column_default :groups, :coc_text_color, '#ffffff'

    reversible do |dir|
      dir.up do
        transaction do
          execute <<-SQL
           UPDATE groups
              SET coc_text_color = '#ffffff'
            WHERE coc_text_color = '#5e2abb'
              AND coc_btn_bg_color = '#5e2abb'
          SQL
        end
      end
    end
  end
end
