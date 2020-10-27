member = message.messagable
joinable = member.joinable
if ['ban_issue_member', 'ban_group_member'].include? message.action.to_s
  body = "@#{message.sender.nickname}님이 회원님을 #{member.joinable.title} #{member.joinable.model_name.human}에서 탈퇴시켰습니다."
  url = smart_joinable_url(joinable)
elsif ['admit_issue_member', 'admit_group_member'].include? message.action.to_s
  body = "@#{message.sender.nickname}님이 회원님을 #{member.joinable.title} #{member.joinable.model_name.human}에 초대했습니다."
  url = smart_joinable_url(joinable)
elsif message.action.to_s == 'force_default_issue'
  body = "@#{message.sender.nickname}님이 #{member.joinable.title} #{member.joinable.model_name.human}를 자동가입되도록 설정했습니다. 해당 #{member.joinable.model_name.human}에 가입되었습니다."
  url = smart_joinable_url(joinable)
elsif ['assign_issue_organizer', 'assign_group_organizer'].include? message.action.to_s
  body = "@#{message.sender.nickname}님이 회원님께 #{member.joinable.title} #{member.joinable.model_name.human} 오거나이징을 부탁했습니다"
  url = smart_joinable_url(joinable)
elsif ['create_issue_organizer', 'create_group_organizer'].include? message.action.to_s
  body = "@#{message.sender.nickname}님이 @#{message.action_params_hash["new_organizer_user_nickname"]}님께 #{member.joinable.title} #{member.joinable.model_name.human} 오거나이징을 부탁했습니다"
  url = smart_joinable_url(joinable)
elsif ['create_issue_member', 'create_group_member'].include? message.action.to_s
  body = "@#{message.sender.nickname}님이 #{joinable.title} #{joinable.model_name.human}에 #{('초대링크로 ' if member.is_magic?)}가입했습니다."
  url = smart_joinable_members_url(joinable)
end

json.data do
  json.id message.id
  json.title "#{joinable.title} #{joinable.class.model_name.human}"
  json.body body
  json.type (joinable.is_a?(Group) ? 'group' : 'parti')
  json.url (fcm_read_front_message_url(id: message.id, url: url) || '')
  json.param joinable.slug
end
