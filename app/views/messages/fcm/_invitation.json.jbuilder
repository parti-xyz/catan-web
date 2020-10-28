invitation = message.messagable
body = "@#{invitation.user.nickname}님이 #{invitation.issue.title} 채널에 초대했습니다."
joinable = invitation.joinable

json.data do
  json.id message.id
  json.title "#{joinable.title} #{joinable.class.model_name.human}"
  json.body body
  json.type (joinable.is_a?(Group) ? 'group' : 'parti')
  json.url (fcm_read_message_url(id: message.id, url: smart_joinable_url(joinable)) || '')
  json.param joinable.slug
end
