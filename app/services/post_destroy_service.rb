class PostDestroyService
  def initialize(post)
    @post = post
  end

  def call
    ActiveRecord::Base.transaction do
      @post.destroy
      Message.where(messagable: @post.survey.try(:options)).destroy_all
      Message.where(messagable: @post.survey).destroy_all
    end
  end
end
