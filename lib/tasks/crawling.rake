namespace :crawling do
  desc "Test"
  task :test, [:url] => :environment do |task, args|
    data = OpenGraph.new(args.url)
    puts data.inspect
  end

  task :auto_test => :environment do
    run_test 'http://www.aladin.co.kr/events/wevent_book.aspx?pn=2016_keyyek_02', title: '[알라딘] "좋은 책을 고르는 방법, 알라딘!"'
    run_test 'http://policy.nec.go.kr/svc/policy/PolicyContent02.do', title: '중앙선거관리위원회_팝업'
    run_test 'http://1000voices.kr/', title: '천인의 소리, 천인의 노래'
    run_test 'https://twitter.com/Elverojaguar/status/714748927631818753', title: '트위터의 The Cult Cat 님: "https://t.co/owcku934Q6"'
    run_test 'http://news.khan.co.kr/kh_news/khan_art_view.html?artid=201603311518461&code=940100', title: '알바노조 “얼굴로 매표하냐, CGV는 ‘꼬질이 벌점’ 없애라”'
    run_test 'http://blog.naver.com/hermes6954/220662731964', title: '바다를 만나고,, 프리다이빙을 시작하고,, 보홀에 샵을 차리기까지..^^'
    run_test 'http://m.todayhumor.co.kr/view.php?table=sisa&no=699146',
      image_original_filename: '1458811502h1NCDLsuo.jpeg',
      image_width: 900,
      image_height: 536
  end

  desc "Show fails"
  task :fails => :environment do
    puts fails.inspect
  end

  desc "Show fail IDs"
  task :fails_id => :environment do
    puts fails.map(&:id).inspect
  end

  desc "Show fail URLs"
  task :fails_url => :environment do
    data = LinkSource.where(title: nil)
    puts fails.map(&:url).inspect
  end

  desc "Reload fail"
  task :reload, [:id] => :environment do
    CrawlingJob.new.perform(id)
    puts id
  end

  desc "Reload all fails"
  task :reload_fails => :environment do
    fails.each do |fail|
      CrawlingJob.new.perform(fail.id)
      puts fail.id
    end
  end

  desc "Reload all"
  task :reload_all => :environment do
    LinkSource.find_each do |source|
      CrawlingJob.new.perform(source.id)
      puts source.id
    end
  end

  def fails
    LinkSource.where(title: nil)
  end

  def run_test(url, expects)
    doc = OpenGraph.new(url)

    pass = true
    puts "TEST: #{url}"
    expects.each do |k,expect|
      if expect == doc.send(k.to_sym)
        puts "  PASS: #{k}"
      else
        pass = false
        puts "  FAIL: #{k} - expect #{expect}, but #{doc.send(k.to_sym)}"
      end
    end

    unless pass
      puts doc.inspect
    end
  end
end
