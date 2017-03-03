namespace :data do
  desc "seed group"
  task 'seed:group' => :environment do
    user = User.find_by(nickname: 'parti')
    Group.transaction do
      seed_group(user, 'gwangju', [],
        name: '광주',
        site_title: '민주주의 플랫폼',
        head_title: '민주주의 플랫폼 - 광주빠띠',
        private: true)

      seed_group(user, 'do', [],
        name: '나는 알아야겠당',
        site_title: 'GMO 완전표시제법',
        head_title: 'GMO 완전표시제법 - 나는 알아야겠당')

      seed_group(user, 'duckup', [],
        name: '덕업넷',
        site_title: '덕후들 모여라',
        head_title: '덕후들 모여라 - 덕업넷')

      seed_group(user, 'change', [],
        name: '바꿈',
        site_title: '세상을 바꾸는 꿈',
        head_title: '세상을 바꾸는 꿈 - 바꿈')

      seed_group(user, 'toktok', [],
        name: '국회톡톡',
        site_title: '내게 필요한 법, 국회에 직접 제안해서 만들어봐요',
        head_title: '내게 필요한 법, 국회에 직접 제안해서 만들어봐요 - 국회톡톡')

      seed_group(user, 'innovators', [],
        name: 'N명의 사회혁신가',
        site_title: '함께 새로운 세상을 만들자',
        head_title: '함께 새로운 세상을 만들자 - N명의 사회혁신가',
        site_description: '사회혁신가는 일상에서 대안과 해결책을 고민하고 제안하며, 구체적인 그림과 방법을 연구하고, 각자의 현장에서 실천하고자 하는 사람들입니다.',
        site_keywords: '함께, 새로운세상을, 만들자, 사회혁신가, 소셜벤처, 박근혜게이트, 정치, 시국선언')

      seed_group(user, 'slowalk', ['rest515'],
        name: '슬로워크',
        site_title: 'Solutions for Change',
        head_title: 'Solutions for Change - 슬로워크')

      seed_group(user, 'westay1', [],
        name: '별내 위스테이 공동체 사회적협동조합',
        site_title: '함께살아보장',
        head_title: '함께살아보장 - 별내 위스테이 공동체 사회적협동조합',
        site_description: '별내지구에 조성될 위스테이 아파트 입주자(조합원)의 온라인 커뮤니케이션 채널입니다. 사회적협동조합의 정관과 사업계획에서 다양한 공동체 소모임까지 조합원들과 함께 만들어 갑니다.')

      seed_group(user, 'wouldyou', [],
        name: '우리가 주인이당',
        site_title: '우주당',
        head_title: '우주당 - 우리가 주인이당',
        site_description: '직접 민주주의 프로젝트 정당 우주당입니다. 우리가 주인이 되어 우리의 이야기로 정치하는, 새롭고 즐거운 시도들을 함께 해요!',
        site_keywords: '정치, 정당, 우주당, 직접민주주의, 해적당, wouldyouparty, 빠띠, 민주주의')

    end
  end

  def seed_group(admin, group_slug, maker_nicknames, options)
    maker_users = User.where(nickname: maker_nicknames)
    group = Group.find_or_initialize_by slug: group_slug
    group.assign_attributes options
    group.user = admin
    maker_users.each do |user|
      next if group.makers.exists?(user: user)
      group.makers.build(user: user)
    end
    group.makers.all.select { |maker| !maker_users.include?(maker.user) }.map &:destroy!
    maker_users.each do |user|
      next if group.members.exists?(user: user)
      group.members.build(user: user)
    end
    group.save!
  end
end
