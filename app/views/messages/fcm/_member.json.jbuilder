member = message.messagable
joinable = member.joinable
if message.action.to_s == 'ban'
  body = "@#{message.sender.nickname}님이 회원님을 #{member.joinable.title} #{member.joinable.model_name.human}에서 탈퇴시켰습니다."
  url = smart_joinable_url(joinable)
elsif message.action.to_s == 'admit'
  body = "@#{message.sender.nickname}님이 회원님을 #{member.joinable.title} #{member.joinable.model_name.human}에 초대했습니다."
  url = smart_joinable_url(joinable)
elsif message.action.to_s == 'force_default'
  body = "@#{message.sender.nickname}님이 #{member.joinable.title} #{member.joinable.model_name.human}를 자동으로 가입되도록 설정했습니다. 해당 #{member.joinable.model_name.human}에 가입되었습니다."
  url = smart_joinable_url(joinable)
elsif message.action.to_s == 'new_organizer'
  body = "@#{message.sender.nickname}님이 회원님께 #{member.joinable.title} #{member.joinable.model_name.human} 오거나이징을 부탁했습니다"
  url = smart_joinable_url(joinable)
elsif message.action.to_s == 'welcome_organizer'
  body = "@#{message.sender.nickname}님이 @#{message.action_params_hash["new_organizer_user_nickname"]}님께 #{member.joinable.title} #{member.joinable.model_name.human} 오거나이징을 부탁했습니다"
  url = smart_joinable_url(joinable)
else
  body = "@#{message.sender.nickname}님이 #{joinable.title} #{joinable.model_name.human}에 #{('초대링크로 ' if member.is_magic?)}가입했습니다."
  url = smart_joinable_members_url(joinable)
end

json.data do
  json.id message.id
  json.title "#{joinable.title} #{joinable.class.model_name.human}"
  json.body body
  json.type (joinable.is_a?(Group) ? 'group' : 'parti')
  json.url (url || '')
  json.param joinable.slug
end
