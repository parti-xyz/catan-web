class AddHiddenIntermediateResultAndHiddenVotersAndExpiresAtToPolls < ActiveRecord::Migration
  def change
    add_column :polls, :hidden_intermediate_result, :boolean, default: false
    add_column :polls, :hidden_voters, :boolean, default: false
    add_column :polls, :expires_at, :datetime
  end
end
