namespace :data do
  desc "seed group"
  task 'seed:group' => :environment do
    user = User.find_by(nickname: 'parti')
    Group.transaction do

      seed_group(user, 'indie', [],
        title: '빠띠',
        site_title: '빠띠',
        head_title: '빠띠')

      seed_group(user, 'gwangju', [],
        title: '광주',
        site_title: '민주주의 플랫폼 - 광주빠띠',
        head_title: '광주')

      seed_group(user, 'do', [],
        title: '나는 알아야겠당',
        site_title: 'GMO 완전표시제법 - 나는 알아야겠당',
        site_description: 'GMO 완전표시제법 통과를 위한 국내 최초 온라인 프로젝트 정당 실험! 세상에 없던 정당의 당원이 되세요',
        head_title: '나알당')

      seed_group(user, 'change', [],
        title: '바꿈',
        site_title: '세상을 바꾸는 꿈 - 바꿈',
        site_description: '세대와 계층을 넘어 바꿈이 세상을 바꿉니다',
        head_title: '바꿈')

      seed_group(user, 'toktok', [],
        title: '국회톡톡',
        site_title: '내게 필요한 법, 국회에 직접 제안해서 만들어봐요 - 국회톡톡',
        site_description: '국회에 직접 제안을 보내세요. 시민의 제안으로 법안을 만듭니다',
        head_title: '국회톡톡')

      seed_group(user, 'innovators', [],
        title: 'N명의 사회혁신가',
        site_title: '함께 새로운 세상을 만들자 - N명의 사회혁신가',
        head_title: 'N명혁신가',
        site_description: '사회혁신가는 일상에서 대안과 해결책을 고민하고 제안하며, 구체적인 그림과 방법을 연구하고, 각자의 현장에서 실천하고자 하는 사람들입니다.',
        site_keywords: '함께, 새로운세상을, 만들자, 사회혁신가, 소셜벤처, 박근혜게이트, 정치, 시국선언')

      seed_group(user, 'slowalk', [],
        title: '슬로워크',
        site_title: '슬로워크',
        head_title: '슬로워크',
        private: true)

      seed_group(user, 'wouldyou', [],
        title: '우주당',
        site_title: '우리가 주인이당 - 우주당',
        head_title: '우주당',
        site_description: '직접 민주주의 프로젝트 정당 우주당입니다. 우리가 주인이 되어 우리의 이야기로 정치하는, 새롭고 즐거운 시도들을 함께 해요!',
        site_keywords: '정치, 정당, 우주당, 직접민주주의, 해적당, wouldyouparty, 빠띠, 민주주의')

      seed_group(user, Group::SLUG_OF_UNION, [],
        title: '빠띠',
        site_title: '민주주의 활동가 그룹 - 빠띠',
        site_description: '빠띠는 민주적인 삶과 문화를 만듭니다. platforms for democratic life and culture',
        head_title: '빠띠',
        private: false)

      seed_group(user, 'meetshare', ['berry', '갱'],
        title: '미트쉐어',
        site_title: '작지만 멋진 일 - 미트쉐어',
        head_title: '미트쉐어',
        site_description: '미트쉐어는 우리 일상 속에서 공익적 가치를 발견하고, 사회에 긍정적인 변화를 가져오는 공익 프로젝트들이 더 많아지길 기대합니다.',
        private: false)

      seed_group(user, 'youthchange', ['천은선'],
        title: '시작된변화',
        site_title: '청소년마을프로젝트 - 시작된변화',
        head_title: '시작된변화',
        site_description: "'마을'을 위해, '사람'을 위해, 청소년이 만들어가는 '변화'. 대책 없는 상상력과 무시무시한 실행력으로 마을의 변화를 만드는 청소년들의 이야기가 흘러넘치는 곳, 시작된변화 빠띠입니다.",
        private: false)

      seed_group(user, 'adaptiveleadership', ['gingertproject'],
        title: '어댑티브 리더십',
        site_title: '함께 읽는 어댑티브 리더십',
        head_title: '변화리더십',
        site_description: "조직의 문제와 나의 문제를 고민하는 사람들이 모여, 이전에는 시도되지 않은 실험을 해나가면서 해결책을 도출해 나가는 변화 리더십에 대한 고민과 생각을 나눕니다.",
        private: false)

      seed_group(user, 'youthpolicynet', ['odong'],
        title: '전국청년정책네트워크',
        site_title: '다음세대를 위한 새로운 시작 - 전국청년정책네트워크',
        head_title: '전청넷',
        site_description: "<전국청년정책네트워크>는 이행기 청년의 불평등 문제를 지역 간 협력과 제도 개선을 통해 해결하는 자발적 시민 네트워크입니다.",
        private: true)

      seed_group(user, 'eduhope', ['옹달샘','이현자'],
        title: '전교조',
        site_title: '교육과 세상을 바꾸는 전교조',
        head_title: '전교조',
        site_description: "교육의 자주성, 전문성 확립과 교육민주화 실현을 위한 전국의 유치원, 초등학교, 중·고등학교 교사들의 자주적 노동조합입니다.",
        private: true)

      seed_group(user, 'syp', ['seoulyouth2014'],
        title: '서울청년의회',
        site_title: '서울청년의회',
        head_title: '청년의회',
        site_description: "정책이 청년의 일상에 가 닿을 수 있도록 청년이 행정에 직접 질의하고, 정책을 발의합니다. 문제의 당사자에서 문제해결의 주체가 되고, 필요와 현실이 반영된 정책이 만들어지는 과정에 참여하는 시민참여의 장입니다.",
        private: false)

      seed_group(user, 'volunteer', ['남문'],
        title: '자원봉사',
        site_title: '자원봉사로 내 삶을 풍성하게 - 자원봉사',
        site_description: "자원봉사의 미래를 설계하기 위해 고민하는 그룹입니다.",
        head_title: '자원봉사',
        private: false)

      seed_group(user, 'kdemo', ['minju30y,isjang'],
        title: '우리가 만드는 나라',
        site_title: '일상 속에서의 민주주의 실현 - 우리가 만드는 나라',
        site_description: "전국적인 온라인 만민공동회 구축을 통해 깨어 있는 시민들의 자발적 네트워크를 구축해 나가는 것을 지향합니다.",
        head_title: '우리만나',
        private: false)

      seed_group(user, 'donghaeng', ['donghaeng'],
        title: '서울동행프로젝트',
        site_title: '대학생과 청소년 동생들이 함께 성장하는 동행 - 서울동행프로젝트',
        site_description: "대학생 자원봉사 전문 플랫폼, 서울동행프로젝트입니다",
        head_title: '서울동행',
        private: false)

      seed_group(user, 'greenpartyjeju', ['rebecca_shin'],
        title: '당다라당당 제주녹색당',
        site_title: '대안의 숲, 전환의 씨앗 - 제주녹색당',
        site_description: "2012년 창당준비위원회 결성한 제주녹색당입니다. 선거제도를 바꾸고, 제주와 나라를 구한 뒤 여유 있으면 창당할게요. 그 모든 과정에 함께 할 생명 옹호자를 만나고 싶어요. 태양과 바람의 정당, 당다라당당 제주녹색당!",
        head_title: '제주녹색당',
        private: false)

      seed_group(user, 'organizer', ['갱', '씽', '달리'],
        title: '오거나이저 커뮤니티',
        site_title: '커뮤니티를 만들고 돌보는 - 오거나이저 커뮤니티',
        site_description: "오거나이저이신가요? 여기서 ‘오거나이징 하는 법’에 대해 같이 이야기해보아요! 빠띠를 통해 조직, 커뮤니티를 더 민주적으로 만들어나가는 오거나이저들의 커뮤니티입니다.",
        head_title: '오거나이저',
        private: false)

      seed_group(user, 'youthmango', ['하늬커'],
        title: '유쓰망고',
        site_title: '청소년들이 만드는 변화 - 유쓰망고',
        site_description: "청소년 체인지메이커들의 커뮤니티입니다. 내 주변의 문제에 공감해 보고, 사회를 변화시키기 위해 무엇이든 행동에 옮겨보는 여러분들의 프로젝트를 공유 해 주세요.",
        head_title: '유쓰망고',
        private: false)

      seed_group(user, 'changemakersym', ['chmym0329'],
        title: '양명고등학교 공감혁신부',
        site_title: '우리부터 시작되는 체인지메이킹 - 양명고등학교 공감혁신부',
        site_description: "저희는 나로부터 시작되는 사회적 이슈를 발견, 해결해나가는 체인지메이커 팀들의 동아리입니다. 저희는 비영리법인 유스망고, 사단법인 아쇼카 한국과 함께 하고 있습니다.",
        head_title: '공감혁신부',
        private: false)

      seed_group(user, 'cairos', ['현준, 갱'],
        title: '연구집단 카이로스',
        site_title: '연구집단 카이로스',
        site_description: "인문사회과학 연구자들의 모임입니다.",
        head_title: '카이로스',
        private: false)

      Issue.where(group_slug: 'duckup').update_all(group_slug: 'indie')
      GroupDestroyService.new('duckup').call
      GroupDestroyService.new('zakdang').call
      GroupDestroyService.new('westay1').call
      GroupDestroyService.new('studio').call
      GroupDestroyService.new('c-time').call
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
