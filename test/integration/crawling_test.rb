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
end
