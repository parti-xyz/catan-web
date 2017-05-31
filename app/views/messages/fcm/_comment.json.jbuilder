comment = message.messagable
json.data do
  json.id message.id
  json.title "#{comment.issue.title} #{Issue.model_name.human}"
  json.body "#{comment.user.nickname}: #{comment.body.try(:truncate, 120)}"
  json.type "post"
  json.priority comment.mentioned?(message.user) ? "high" : "low"
  json.param comment.post.id
end
