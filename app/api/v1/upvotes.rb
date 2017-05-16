module V1
  class Upvotes < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :upvotes do
      desc '공감합니다'
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

        return_no_content
      end

      desc '공감을 취소합니다'
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

        return_no_content
      end

      desc '특정 게시글의 공감들을 반환합니다'
      oauth2
      params do
        requires :post_id, type: Integer
        optional :last_id, type: Integer, desc: '이전에 보고있던 마지막 공감번호'
      end
      get 'of_post' do
        post = Post.find(params[:post_id])
        upvote_base = post.upvotes.recent

        @upvotes = upvote_base.limit(25)
        @upvotes = @upvotes.where('id < ?', params[:last_id]) if params[:last_id].present?
        current_last = @upvotes.last
        @has_more_item = (upvote_base.any? and upvote_base.where('id < ?', current_last.try(:id)).any?)

        present :has_more_item, @has_more_item
        present :items, @upvotes
      end
    end

  end
end
