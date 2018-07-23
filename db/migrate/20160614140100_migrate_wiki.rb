class MigrateWiki < ActiveRecord::Migration[4.2]
  def up
    issues = Issue.with_deleted.select {|i| i.wiki.nil? }
    issues.each do |issue|
      issue.create_wiki
    end
  end
end
