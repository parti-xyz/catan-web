class MigrateWiki < ActiveRecord::Migration
  def up
    issues = Issue.with_deleted.select {|i| i.wiki.nil? }
    issues.each do |issue|
      issue.create_wiki
    end
  end
end
