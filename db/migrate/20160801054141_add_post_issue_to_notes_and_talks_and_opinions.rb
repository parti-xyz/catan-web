class AddPostIssueToNotesAndTalksAndOpinions < ActiveRecord::Migration
  def up
    #add_reference :notes, :post_issue
    add_reference :talks, :post_issue
    add_reference :opinions, :post_issue

    query = "UPDATE notes SET post_issue_id = (SELECT posts.issue_id FROM posts WHERE posts.postable_type = 'Note' and notes.id = posts.postable_id)"
    ActiveRecord::Base.connection.execute query
    say query
    query = "UPDATE talks SET post_issue_id = (SELECT posts.issue_id FROM posts WHERE posts.postable_type = 'Talk' and talks.id = posts.postable_id)"
    ActiveRecord::Base.connection.execute query
    say query
    query = "UPDATE opinions SET post_issue_id = (SELECT posts.issue_id FROM posts WHERE posts.postable_type = 'Opinion' and opinions.id = posts.postable_id)"
    ActiveRecord::Base.connection.execute query
    say query

    change_column_null :notes, :post_issue_id, false
    change_column_null :talks, :post_issue_id, false
    change_column_null :opinions, :post_issue_id, false
  end

  def down
    remove_column :notes, :post_issue_id
    remove_column :talk, :post_issue_id
    remove_column :talk, :post_issue_id
  end
end
