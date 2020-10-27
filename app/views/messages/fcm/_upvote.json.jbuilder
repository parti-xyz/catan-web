upvote = message.messagable
post = upvote.post
issue = message.messagable.issue
if upvote.upvotable.is_a? Comment
  comment = upvote.upvotable
  post = upvote.upvotable.post
  body = "@#{message.sender.nickname}님이 내 댓글에 공감합니다. \"#{comment.body.try(:truncate, 120)}\""

  json.data do
    json.id message.id
    json.title "#{comment.issue.title} #{Issue.model_name.human}"
    json.body body
    json.type "comment"
    json.url fcm_read_front_message_url(id: message.id, url: comment_url(comment))
    json.param comment.id
  end
else
  post = upvote.upvotable
  body = "@#{message.sender.nickname}님이 내 게시글을 공감합니다. \"#{post.specific_desc_striped_tags(100)}\""

  json.data do
    json.id message.id
    json.title "#{issue.title} #{Issue.model_name.human}"
    json.body body
    json.type "post"
    json.url fcm_read_front_message_url(id: message.id, url: smart_post_url(post))
    json.param post.id
  end
end


