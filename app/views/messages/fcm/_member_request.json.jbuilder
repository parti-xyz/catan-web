member_request = message.messagable
joinable = member_request.joinable
if ['create_issue_member_request', 'create_group_member_request'].include? message.action.to_s
  body = "@#{message.sender.nickname}님이 #{member_request.joinable.title} #{member_request.joinable.model_name.human}에 가입요청합니다."
  url = smart_joinable_members_url(joinable)
end
if ['accept_issue_member_request', 'accept_group_member_request'].include? message.action.to_s
  body = "@#{message.sender.nickname}님이 #{member_request.joinable.title} #{member_request.joinable.model_name.human} 가입요청을 승인합니다."
  url = smart_joinable_url(joinable)
end
if ['reject_issue_member_request', 'reject_group_member_request'].include? message.action.to_s
  body = "@#{message.sender.nickname}님이 #{member_request.joinable.title} #{member_request.joinable.model_name.human} 가입요청을 거절합니다."
  url = smart_joinable_url(joinable)
end

json.data do
  json.id message.id
  json.title "#{joinable.title} #{joinable.class.model_name.human}"
  json.body body
  json.type (joinable.is_a?(Group) ? 'group' : 'parti')
  json.url (fcm_read_message_url(id: message.id, url: url) || '')
  json.param joinable.slug
end
