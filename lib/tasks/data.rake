namespace :data do
  desc "seed group"
  task 'seed:group' => :environment do
    user = User.find_by(nickname: 'parti')
    Group.transaction do
      seed_group(user, 'indie', [],
        title: '개인 커뮤니티',
        site_title: '개인 커뮤니티',
        head_title: '개인')
    end
  end

  def seed_group(admin, group_slug, organizer_nicknames, options)
    organizer_users = User.where(nickname: organizer_nicknames)
    group = Group.find_or_initialize_by slug: group_slug
    group.assign_attributes({ private: false }.merge(options))
    group.user = admin
    organizer_users.each do |user|
      organizer_member = group.members.find_or_initialize_by(user: user)
      organizer_member.is_organizer = true
    end
    if !group.private?
      group.members.where(is_organizer: true).select do |member|
        !organizer_users.include?(member.user)
      end.map do |member|
        member.update_columns(is_organizer: false)
      end
    end

    group.save!
    group
  end
end
