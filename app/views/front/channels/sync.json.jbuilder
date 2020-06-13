json.array!(@issues) do |issue|
  json.id issue.id
  json.needToRead issue.need_to_read?(current_user)
end