require 'test_helper'

class CrawlingTest < ActionDispatch::IntegrationTest
  focus
  test '알라딘' do
    skip
    doc = OpenGraph.new('http://www.aladin.co.kr/events/wevent_book.aspx?pn=2016_keyyek_02')
    assert_equal "[알라딘] \"좋은 책을 고르는 방법, 알라딘!\"", doc.title
  end
end
