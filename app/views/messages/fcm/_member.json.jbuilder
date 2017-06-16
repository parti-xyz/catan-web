member = message.messagable
joinable = member.joinable
if message.action.to_s == 'ban'
  body = "#{message.sender.nickname}님이 회원님을 #{member.joinable.title} #{member.joinable.model_name.human}에서 탈퇴시켰습니다."
elsif message.action.to_s == 'admit'
  body = "#{message.sender.nickname}님이 회원님을 #{member.joinable.title} #{member.joinable.model_name.human}에 가입시켰습니다."
else
  body = "#{message.sender.nickname}님이 #{joinable.title} #{joinable.model_name.human}에 #{('초대링크로 ' if member.is_magic?)}가입했습니다."
end

json.data do
  json.id message.id
  json.title "#{joinable.title} #{joinable.class.model_name.human}"
  json.body body
  json.type (joinable.is_a?(Group) ? 'group' : 'parti')
  json.url (smart_joinable_url(joinable) || '')
  json.param joinable.slug
end