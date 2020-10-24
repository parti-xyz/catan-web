announcement = message.messagable
post = announcement.post
issue = post.issue
if message.action.to_s == 'create_announcement'
  body = "게시글 필독요청을 받았습니다."
else
  body = ""
end

json.data do
  json.id message.id
  json.title "#{issue.title} #{Issue.model_name.human}"
  json.body body
  json.type "post"
  json.priority "high"
  json.url smart_post_url(post)
  json.param post.id
end
