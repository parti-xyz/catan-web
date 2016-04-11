class ChangeNullCrawlingStatusOfLinkSources < ActiveRecord::Migration
  def change
    change_column_null :link_sources, :crawling_status, false
  end
end
