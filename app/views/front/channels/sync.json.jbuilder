if @need_to_notice_count.present? && @need_to_notice_count > 0
  json.needToNoticeCount number_to_human(@need_to_notice_count, precision: 1, delimiter: ',', significant: false)
end
json.announcementsMenuUrl front_announcements_path(filter: { condition: ('needtonotice' if @need_to_notice_count.present? && @need_to_notice_count > 0) })

if @unread_messages_count.present? && @unread_messages_count >0
  json.unreadMessagesCount number_to_human(@unread_messages_count, precision: 1, delimiter: ',', significant: false)
end
json.messagesMenuUrl front_messages_path(filter: { condition: ('needtoread' if @unread_messages_count.present? && @unread_messages_count > 0) })

if @unread_mentions_count.present? && @unread_mentions_count >0
  json.unreadMentionsCount number_to_human(@unread_mentions_count, precision: 1, delimiter: ',', significant: false)
end
json.mentionsMenuUrl front_mentions_path(filter: { condition: ('needtoread' if @unread_mentions_count.present? && @unread_mentions_count > 0) })

json.channels @issues do |issue|
  json.id issue.id
  json.needToRead issue.need_to_read?(current_user)
end