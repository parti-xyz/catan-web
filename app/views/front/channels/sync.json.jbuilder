if @need_to_notice_count.present? && @need_to_notice_count > 0
  json.needToNoticeCount number_to_human(@need_to_notice_count, precision: 1, delimiter: ',', significant: false)
end
json.channels @issues do |issue|
  json.id issue.id
  json.needToRead issue.need_to_read?(current_user)
end