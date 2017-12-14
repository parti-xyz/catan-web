class IssueFirebaseRealtimeDb
  include Sidekiq::Worker

  def perform(issue_id, user_id)
    if !Rails.env.production?
      return if ENV["FIREBASE"] != 'true'
    end

    issue = Issue.find_by(id: issue_id)
    return if issue.blank?

    firebase = Firebase::Client.new("https://parti-xyz.firebaseio.com", Rails.root.join('config', 'firebase-serviceAccountCredentials.json'))
    firebase.set("#{bucket_name}/parties/#{issue.id}", {
      last_stroked_at: (issue.last_stroked_at.try(:to_time).try(:to_i) || -1),
      last_stroked_by: user_id
    })
  end

  def bucket_name
    if Rails.env.production? or Rails.env.staging?
      Rails.env
    else
      if ENV["FIREBASE_BUCKETNAME"].blank?
        "#{Rails.env}/#{rand(100..999)}"
      else
        "#{Rails.env}/#{ENV["FIREBASE_BUCKETNAME"]}"
      end
    end
  end
end
