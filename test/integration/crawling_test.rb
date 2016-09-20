require 'test_helper'

class CrawlingTest < ActionDispatch::IntegrationTest
  test '알라딘' do
    skip
    doc = OpenGraph.new('http://www.aladin.co.kr/events/wevent_book.aspx?pn=2016_keyyek_02')
    assert_equal "[알라딘] \"좋은 책을 고르는 방법, 알라딘!\"", doc.title
  end

  test '중앙선거관리' do
    skip
    doc = OpenGraph.new('http://policy.nec.go.kr/svc/policy/PolicyContent02.do')
    assert_equal "중앙선거관리위원회_팝업", doc.title
  end

  test '천인의 소리, 천인의 노래' do
    skip
    doc = OpenGraph.new('http://1000voices.kr/')
    assert_equal "천인의 소리, 천인의 노래", doc.title
  end

  test '[이슈 돋보기] 부르키니, 여성 억압인가 해방인가' do
    skip
    doc = OpenGraph.new('https://upfrontfeminism.wordpress.com/2016/08/25/%EC%9D%B4%EC%8A%88-%EB%8F%8B%EB%B3%B4%EA%B8%B0-%EB%B6%80%EB%A5%B4%ED%82%A4%EB%8B%88-%EC%97%AC%EC%84%B1-%EC%96%B5%EC%95%95%EC%9D%B8%EA%B0%80-%ED%95%B4%EB%B0%A9%EC%9D%B8%EA%B0%80/')
    assert_equal "https://i.guim.co.uk/img/media/430aef085ae4cc228a624005370b8a22ecbaa72b/348_28_889_1111/master/889.jpg?w=300&q=55&auto=format&usm=12&fit=max&s=f6a48c5560011e486058070232b7b415", doc.images.first
  end
end
