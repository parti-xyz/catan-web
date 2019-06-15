
issue = message.messagable

if message.action.to_s == 'edit_title'
  body = "@#{message.sender.nickname}님이 #{message.action_params_hash["previous_title"]} 채널 이름을 #{issue.title} 채널로 수정했습니다"
elsif message.action.to_s == 'create'
  body = "@#{message.sender.nickname}님이 #{issue.group.title_basic_format}의 #{issue.title} 채널을 새로 열었습니다"
end

json.data do
  json.id message.id
  json.title "#{issue.title} #{Issue.model_name.human}"
  json.body body
  json.type "parti"
  json.param issue.slug
  json.url (smart_issue_home_url(issue) || '')
end

