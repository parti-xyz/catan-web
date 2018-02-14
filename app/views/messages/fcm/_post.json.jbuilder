post = message.messagable
issue = post.issue
if message.action.to_s == 'pinned'
  body = "@#{message.sender.nickname}님이 게시글을 공지했습니다. \"#{post.specific_desc_striped_tags(100)}\""
elsif message.action.to_s == 'decision'
  body = "@#{message.sender.nickname}님이 결론을 업데이트 했습니다. \"#{message.action_params_hash["decision_body"].try(:truncate, 100)}\""
else
  body = "#{post.user.nickname}: #{post.specific_desc_striped_tags(100)}"
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
