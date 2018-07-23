class AddIssueIdToUpvotes < ActiveRecord::Migration[4.2]
  def change
    add_reference :upvotes, :issue, index: true

    Upvote.all.each do |u|
      u.update_columns(issue_id: u.upvotable.issue.id)
    end

    change_column_null :upvotes, :issue_id, :false
  end
end
