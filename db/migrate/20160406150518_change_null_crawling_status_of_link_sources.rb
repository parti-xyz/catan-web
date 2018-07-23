class ChangeNullCrawlingStatusOfLinkSources < ActiveRecord::Migration[4.2]
  def change
    change_column_null :link_sources, :crawling_status, false
  end
end
