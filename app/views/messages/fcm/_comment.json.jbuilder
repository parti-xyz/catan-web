comment = message.messagable
json.data do
  json.id message.id
  json.title "#{comment.issue.title} #{Issue.model_name.human}"
  json.body "@#{comment.user.nickname}: #{excerpt(comment.body_striped_tags, length: 120)}"
  json.type "comment"
  json.url fcm_read_message_url(id: message.id, url: comment_url(comment))
  json.priority comment.mentioned?(message.user) ? "high" : "low"
  json.param comment.id
end
