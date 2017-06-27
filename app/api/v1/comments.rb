module V1
  class Comments < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :comments do
      helpers do
        def set_choice(comment)
          voting = comment.post.voting_by resource_owner
          comment.choice = voting.try(:choice)
        end
      end

      desc '댓글을 답니다'
      oauth2
      params do
        requires :comment, type: Hash do
          requires :body, type: String
          requires :post_id, type: Integer
        end
      end
      post do
        @comment = Comment.new permitted(params, :comment)
        @comment.user = resource_owner

        error!(:not_found, 410) and return if @comment.post.blank? or @comment.post.private_blocked?(current_user)
        error!(:forbidden, 403) and return if @comment.post.private_blocked?(resource_owner)

        set_choice @comment

        @comment.save!
        @comment.perform_mentions_async

        present @comment, base_options.merge(type: :full)
      end

      desc '댓글을 지웁니다'
      oauth2
      params do
        requires :id, type: Integer, desc: '지울 댓글 번호'
      end
      delete ':id' do
        @comment = Comment.find_by(id: params[:id])

        error!(:not_found, 410) and return if @comment.blank?

        authorize! :destroy, @comment
        @comment.destroy!
      end
    end
  end
end
