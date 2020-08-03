class AddGroupIdToLabels < ActiveRecord::Migration[5.2]
  class Label < ActiveRecord::Base
    belongs_to :deprecated_issue, class_name: 'AddGroupIdToLabels::Issue'
    belongs_to :group, counter_cache: true, class_name: 'AddGroupIdToLabels::Group'
    has_many :posts, class_name: 'AddGroupIdToLabels::Post'
  end

  class Issue < ActiveRecord::Base
    has_many :labels, class_name: 'AddGroupIdToLabels::Label'
  end

  class Group < ActiveRecord::Base
    has_many :labels, class_name: 'AddGroupIdToLabels::Label'
  end

  class Post < ActiveRecord::Base
    belongs_to :label, counter_cache: true, optional: true, class_name: 'AddGroupIdToLabels::Label'
  end

  def change
    change_column_null :labels, :issue_id, true
    rename_column :labels, :issue_id, :deprecated_issue_id
    remove_column :issues, :labels_count, :integer, default: 0
    add_reference :labels, :group, index: true
    add_column :groups, :labels_count, :integer, default: 0
    reversible do |dir|
      dir.up do
        transaction do
          Label.all.each do |label|
            label.update_columns(group_id: Group.find_by_slug(label.deprecated_issue.group_slug).id)
          end

          Label.all.to_a.group_by { |label| [label.group_id, label.title] }.select{ |key, labels| labels.size > 1 }.each do |(group_id, _), labels|
            group = Group.find(group_id)

            first_label = labels.first
            Post.where(label_id: labels).update_all(label_id: first_label.id)

            labels.each_with_index do |label, index|
              Label.reset_counters(label.id, :posts)
              if index > 0
                if label.reload.posts_count > 0
                  raise "중복 라벨 오류"
                end
                label.destroy!
              end
            end
          end

          Label.group(:group_id).pluck(:group_id).each  do |group_id|
            Group.reset_counters(group_id, :labels)
          end
        end
      end
    end
  end
end
