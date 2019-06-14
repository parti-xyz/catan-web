class AddLogoToGroups < ActiveRecord::Migration[5.2]
  def change
    add_column :groups, :logo, :string

    reversible do |dir|
      dir.up do
        Group.with_deleted.all.each do |group|
          return if group.logo?
          if group.slug == 'naafidha_newsshare'
            group.slug = 'naafidha-newsshare'
          end
          if group.slug == 'enterprise_slowalk'
            group.slug = 'enterprise-slowalk'
          end
          group.logo = "data:image/png;base64,#{Catan::Avatar::generate_avatar(group.title)}"
          group.save!
          print "."
        end

        puts "."

        change_column_null :groups, :logo, false
      end
    end
  end
end
