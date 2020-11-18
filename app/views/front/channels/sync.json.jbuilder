if @need_to_notice_count.present? && @need_to_notice_count > 0
  json.needToNoticeCount number_to_human(@need_to_notice_count, precision: 1, delimiter: ',', significant: false)
end

if @unread_messages_count.present? && @unread_messages_count >0
  json.unreadMessagesCount number_to_human(@unread_messages_count, precision: 1, delimiter: ',', significant: false)
end

if @unread_mentions_count.present? && @unread_mentions_count >0
  json.unreadMentionsCount number_to_human(@unread_mentions_count, precision: 1, delimiter: ',', significant: false)
end

if @bookmarks_count.present? && @bookmarks_count >0
  json.bookmarksCount number_to_human(@bookmarks_count, precision: 1, delimiter: ',', significant: false)
end

json.channels @issues do |issue|
  json.id issue.id
  json.needToRead issue.need_to_read?(current_user)
end