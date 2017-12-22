class MonitorPostsErrorJob
  include Sidekiq::Worker
  sidekiq_options unique: :while_executing

  def perform
    null_result = ActiveRecord::Base.connection.execute("select count(*) from posts where deleted_at is NULL and issue_id = 16").to_a[0][0]
    not_null_result = ActiveRecord::Base.connection.execute("select count(*) from posts where deleted_at is not NULL and issue_id = 16").to_a[0][0]
    if null_result == 0 or not_null_result == 0
      raise "@dalikim @ganguri 무한 스크롤 에러가 발생하는 것 같다! 고쳐줘!"
    end
  end
end
