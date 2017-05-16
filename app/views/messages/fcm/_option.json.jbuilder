option = message.messagable
post = option.survey.post
issue = post.issue
body = "#{option.user.nickname}님이 새로운 제안을 올렸습니다. \"#{option.body}\""

json.data do
  json.title "#{issue.title} #{Issue.model_name.human}"
  json.body body
  json.type "post"
  json.param post.id
end
