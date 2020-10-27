comment = message.messagable
json.data do
  json.id message.id
  json.title "#{comment.issue.title} #{Issue.model_name.human}"
  json.body "@#{comment.user.nickname}: #{comment.body.try(:truncate, 120)}"
  json.type "comment"
  json.url fcm_read_front_message_url(id: message.id, url: comment_url(comment))
  json.priority comment.mentioned?(message.user) ? "high" : "low"
  json.param comment.id
end
