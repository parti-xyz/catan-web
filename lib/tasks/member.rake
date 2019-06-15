namespace :member do
  desc "그룹의 멤버 중에 해당 그룹의 멤버가 아닌 경우, 해당 그룹에 가입시킵니다"
  task :straggler => :environment do
    Group.but(Group.indie).map do |group|
      puts "==> Group : #{group.title} #{group.slug}"
      (group.comprehensive_joined_users - group.member_users).each do |user|
        if group.private?
          puts " private group skip: #{user.id} #{user.nickname}"
        else
          @member = MemberGroupService.new(group: group, user: user).call
          if @member.present? and @member.persisted?
            puts " add: #{user.id} #{user.nickname}"
          else
            puts " fail: #{user.id} #{user.nickname}"
          end
        end
      end
    end
  end

  desc "공개그룹의 멤버 중에 해당 개별의 멤버가 아닌 경우를 찾아 봅니다"
  task :zombie => :environment do
    Member.deleted.where(joinable_type: Issue).each do |member|
      user = User.find_by(id: member.user_id)
      next if user.blank?

      issue = Issue.with_deleted.find_by(id: member.joinable_id)

      group = issue.try(:group)
      next if group == nil or group.private? or group.organized_by?(user)

      issues = group.issues
      if !issues.any? { |issue| issue.member?(user) }
        member = group.member_of(user)
        if member.present?
          puts "#{group.slug} : #{user.nickname}"
        end
      end
    end
  end

end
