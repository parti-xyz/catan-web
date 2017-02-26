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

      desc '댓글을 지웁니다'
      oauth2
      params do
        requires :id, type: Integer, desc: '지울 댓글 번호'
      end
      delete ':id' do
        @comment = Comment.find(params[:id])
        authorize! :destroy, @comment
        @comment.destroy!
      end

      desc '한 게시글의 댓글을 반환합니다.'
      oauth2
      params do
        requires :post_id, type: Integer, desc: '게시글 번호'
        optional :last_id, type: Integer, desc: '이전 마지막 댓글 번호'
      end
      get 'by_post' do
        @post = Post.find(params[:post_id])
        base_comments = @post.comments.recent

        previous_last_comment = Comment.with_deleted.find_by(id: params[:last_id])
        @comments = base_comments.limit(25).previous_of(previous_last_comment.try(:id))

        current_last_comment = @comments.last

        @has_more_item = (base_comments.any? and base_comments.previous_of(current_last_comment.try(:id)).any?)

        present :has_more_item, @has_more_item
        present :items, @comments, base_options.merge(type: :full)
      end
    end

  end
end
