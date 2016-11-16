module V1
  class Invitations < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :invitations do
      desc '이메일로 초대했습니다'
      oauth2
      params do
        requires :parti_id, type: Integer
        requires :emails, type: Array[String]
      end
      post 'by_emails' do
        issue = Issue.find_by id: params[:parti_id]
        return if issue.blank?

        params[:emails].reject{ |email| issue.member_email? email }.each do |email|
          InvitationMailer.invite_parti_by_email(resource_owner.id, email, issue.id).deliver_later
        end
      end

      desc '닉네임으로 초대했습니다'
      oauth2
      params do
        requires :parti_id, type: Integer
        requires :nicknames, type: Array[String]
      end
      post 'by_nicknames' do
        issue = Issue.find_by id: params[:parti_id]
        return if issue.blank?

        params[:nicknames].map { |nickname| User.find_by nickname: nickname }.compact.reject{ |user| issue.member? user.nickname }.each do |user|
          invitation = Invitation.new(user: resource_owner, recipient: user, issue: issue);
          invitation.messages.build(messagable: invitation, sender: resource_owner, user: user)
          if invitation.save
            InvitationMailer.invite_parti_by_nickname(resource_owner.id, user.id, issue.id).deliver_later
          end
        end
      end
    end

  end
end
