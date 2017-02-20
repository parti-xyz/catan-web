namespace :data do
  desc "seed group"
  task 'seed:group' => :environment do
    user = User.find_by(nickname: 'parti')
    Group.transaction do
      Group.find_or_create_by!(slug: 'gwangju') do |group|
        group.assign_attributes(
          user: user,
          name: '광주',
          site_title: '민주주의 플랫폼',
          head_title: '민주주의 플랫폼 - 광주빠띠')
      end

      Group.find_or_create_by!(slug: 'do') do |group|
        group.assign_attributes(
          user: user,
          name: '나는 알아야겠당',
          site_title: 'GMO 완전표시제법',
          head_title: 'GMO 완전표시제법 - 나는 알아야겠당')
      end

      Group.find_or_create_by!(slug: 'duckup') do |group|
        group.assign_attributes(
          user: user,
          name: '덕업넷',
          site_title: '덕후들 모여라',
          head_title: '덕후들 모여라 - 덕업넷')
      end

      Group.find_or_create_by!(slug: 'change') do |group|
        group.assign_attributes(
          user: user,
          name: '바꿈',
          site_title: '세상을 바꾸는 꿈',
          head_title: '세상을 바꾸는 꿈 - 바꿈')
      end

      Group.find_or_create_by!(slug: 'toktok') do |group|
        group.assign_attributes(
          user: user,
          name: '국회톡톡',
          site_title: '내게 필요한 법, 국회에 직접 제안해서 만들어봐요',
          head_title: '내게 필요한 법, 국회에 직접 제안해서 만들어봐요 - 국회톡톡')
      end

      Group.find_or_create_by!(slug: 'innovators') do |group|
        group.assign_attributes(
          user: user,
          name: 'N명의 사회혁신가',
          site_title: '함께 새로운 세상을 만들자',
          head_title: '함께 새로운 세상을 만들자 - N명의 사회혁신가',
          site_description: '사회혁신가는 일상에서 대안과 해결책을 고민하고 제안하며, 구체적인 그림과 방법을 연구하고, 각자의 현장에서 실천하고자 하는 사람들입니다.',
          site_keywords: '함께, 새로운세상을, 만들자, 사회혁신가, 소셜벤처, 박근혜게이트, 정치, 시국선언')
      end

      Group.find_or_create_by!(slug: 'slowalk') do |group|
        group.assign_attributes(
          user: user,
          name: '슬로워크',
          site_title: 'Solutions for Change',
          head_title: 'Solutions for Change - 슬로워크')
      end
    end
  end
end
