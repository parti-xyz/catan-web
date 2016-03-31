namespace :crawling do
  desc "Test"
  task :test, [:url] => :environment do |task, args|
    data = OpenGraph.new(args.url)
    puts data.inspect
  end

  task :auto_test => :environment do
    run_test 'http://www.aladin.co.kr/events/wevent_book.aspx?pn=2016_keyyek_02', '[알라딘] "좋은 책을 고르는 방법, 알라딘!"'
    run_test 'http://policy.nec.go.kr/svc/policy/PolicyContent02.do', '중앙선거관리위원회_팝업'
    run_test 'http://1000voices.kr/', '천인의 소리, 천인의 노래'
    run_test 'https://twitter.com/Elverojaguar/status/714748927631818753', '트위터의 The Cult Cat 님: "https://t.co/owcku934Q6"'
    run_test 'http://news.khan.co.kr/kh_news/khan_art_view.html?artid=201603311518461&code=940100', '알바노조 “얼굴로 매표하냐, CGV는 ‘꼬질이 벌점’ 없애라”'
  end

  task :fails => :environment do
    puts fails.inspect
  end

  task :fails_id => :environment do
    puts fails.map(&:id).inspect
  end

  task :fails_url => :environment do
    data = LinkSource.where(title: nil)
    puts fails.map(&:url).inspect
  end

  task :reload, [:id] => :environment do
    puts CrawlingJob.perform_async(id).to_s
  end

  task :reload_fails => :environment do
    fails.each do |fail|
      puts CrawlingJob.perform_async(fail.id).to_s
    end
  end

  def fails
    LinkSource.where(title: nil)
  end

  def run_test(url, expect_title)
    doc = OpenGraph.new(url)
    if expect_title == doc.title
      puts "PASS: #{url}"
    else
      puts "FAIL: #{url}"
      puts doc.inspect
    end
  end
end
