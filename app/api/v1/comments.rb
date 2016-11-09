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
        set_choice @comment
        @comment.save!
        present :comment, @comment, type: :full
      end
    end

  end
end
