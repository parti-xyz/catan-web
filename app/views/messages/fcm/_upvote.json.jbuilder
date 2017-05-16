upvote = message.messagable
post = upvote.post
issue = message.messagable.issue
if upvote.upvotable.is_a? Comment
  post = upvote.upvotable.post
  body = "#{message.sender.nickname}님이 내 댓글에 공감합니다. \"#{post.specific_desc_striped_tags(100)}\""
else
  post = upvote.upvotable
  body = "#{message.sender.nickname}님이 내 게시글을 공감합니다. \"#{post.specific_desc_striped_tags(100)}\""
end

json.data do
  json.title "#{issue.title} #{Issue.model_name.human}"
  json.body body
  json.type "post"
  json.param post.id
end
