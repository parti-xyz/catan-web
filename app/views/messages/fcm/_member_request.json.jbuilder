member_request = message.messagable
joinable = member_request.joinable
if message.action.to_s == 'request'
  body = "@#{message.sender.nickname}님이 #{member_request.joinable.title} #{member_request.joinable.model_name.human}에 가입요청합니다."
end
if message.action.to_s == 'accept'
  body = "@#{message.sender.nickname}님이 #{member_request.joinable.title} #{member_request.joinable.model_name.human} 가입요청을 승인합니다."
end
if message.action.to_s == 'cancel'
  body = "@#{message.sender.nickname}님이 #{member_request.joinable.title} #{member_request.joinable.model_name.human} 가입요청을 거절합니다."
end

json.data do
  json.id message.id
  json.title "#{joinable.title} #{joinable.class.model_name.human}"
  json.body body
  json.type (joinable.is_a?(Group) ? 'group' : 'parti')
  json.url (smart_joinable_url(joinable) || '')
  json.param joinable.slug
end
