namespace :data do
  desc "seed group"
  task 'seed:group' => :environment do
    user = User.find_by(nickname: 'parti')
    Group.transaction do
      indie = Group.find_by(slug: 'indie')
      if indie.present?
        indie.update_columns(slug: 'open')
      end
      Category.where(group_slug: 'indie').update_all(group_slug: 'open')
      Issue.where(group_slug: 'indie').update_all(group_slug: 'open')
      MergedIssue.where(source_group_slug: 'indie').update_all(source_group_slug: 'open')
      seed_group(user, 'open', [],
        title: '열린 광장',
        site_title: '열린 광장',
        head_title: '열린 광장')
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
