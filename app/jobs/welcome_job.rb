class WelcomeJob < ApplicationJob
  include Sidekiq::Worker
  sidekiq_options unique: :while_executing

  def perform
    #기획
    # 신규 가입 시 이메일을 발송한다.
    # 30분 내로 배치가 돈다?
    #
    # 할일
    # 신규 가입 모듈을 분석해서 어디즈음에서 웰컴 작업을 호출할지 결정한다
    # 특정 계정에게 웰컴 메일을 발송한다.
    # 웰컴 메일에 임시 내용이 보인다.
    #
    # 웰컴 메일에 모든 내용이 보인다.
  end
end
