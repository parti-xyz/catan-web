event = message.messagable

if message.action.to_s == 'invite'
  body = "@#{message.sender.nickname}님이 일정 \"#{event.title}\"에 초대했습니다"
elsif message.action.to_s == 'schedule'
  body = "@#{message.sender.nickname}님이 일정 \"#{event.title}\"의 시간을 바꾸고 참석 여부 확인을 요청했습니다."
elsif message.action.to_s == 'location'
  body = "@#{message.sender.nickname}님이 일정 \"#{event.title}\"에 장소를 바꾸고 참석 여부 확인을 요청했습니다."
end

json.data do
  json.id message.id
  json.title "#{Event.model_name.human} \"#{event.title}\""
  json.body body
  json.type "post"
  json.param event.post.id
  json.url smart_post_url(event.post)
end
