module V1
  class Upvotes < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :upvotes do
      desc '좋아합니다'
      oauth2
      params do
        requires :upvote, type: Hash do
          requires :upvotable_type, type: String
          requires :upvotable_id, type: Integer
        end
      end
      post do
        @upvote = Upvote.where(user: resource_owner).find_by permitted(params, :upvote)
        return if @upvote.present?

        @upvote = Upvote.new permitted(params, :upvote)
        @upvote.user = resource_owner
        @upvote.save!
      end

      desc '좋아한 것을 취소합니다'
      oauth2
      params do
        requires :upvote, type: Hash do
          requires :upvotable_type, type: String
          requires :upvotable_id, type: Integer
        end
      end
      delete do
        @upvote = Upvote.where(user: resource_owner).find_by permitted(params, :upvote)
        @upvote.destroy! if @upvote.present?
      end
    end

  end
end
