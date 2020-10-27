survey = message.messagable
post = survey.post
issue = post.issue
body = "@#{post.user.nickname}님이 올린 설문의 결과가 나왔습니다. \"#{post.specific_desc_striped_tags(100)}\""

json.data do
  json.id message.id
  json.title "#{issue.title} #{Issue.model_name.human}"
  json.body body
  json.type "post"
  json.url fcm_read_front_message_url(id: message.id, url: smart_post_url(post))
  json.param post.id
end
