class ChangeDefaultNavbarBgColorOfGroups < ActiveRecord::Migration[5.2]
  def change
    change_column_default :groups, :navbar_coc_text_color, '#5e2abb'

    reversible do |dir|
      dir.up do
        transaction do
          execute <<-SQL
           UPDATE groups
              SET navbar_coc_text_color = '#5e2abb'
            WHERE navbar_coc_text_color = '5e2abb'
          SQL
        end
      end
    end
  end
end
