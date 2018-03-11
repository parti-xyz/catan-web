namespace :member do
  desc "그룹의 빠띠 멤버 중에 해당 그룹의 멤버가 아닌 경우, 해당 그룹에 가입시킵니다"
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
end
