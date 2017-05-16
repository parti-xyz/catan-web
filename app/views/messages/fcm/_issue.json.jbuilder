issue = message.messagable
body = "#{message.sender.nickname}님이 #{message.action_params_hash["previous_title"]} 빠띠 이름을 #{issue.title} 빠띠로 수정했습니다"

json.data do
  json.title "#{issue.title} #{Issue.model_name.human}"
  json.body body
  json.type "parti"
  json.param issue.slug
  json.url (smart_issue_home_url(issue) || '')
end

