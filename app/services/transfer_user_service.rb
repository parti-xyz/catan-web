class TransferUserService

  attr_accessor :source_nickname
  attr_accessor :target_nickname

  def initialize(source_nickname:, target_nickname:)
    @source_nickname = source_nickname
    @target_nickname = target_nickname
  end

  def call
    source_user = User.find_by nickname: @source_nickname
    target_user = User.find_by nickname: @target_nickname
    transfer_data(source_user, target_user)
  end

  def transfer_data(source_user, target_user)
    [Post, Comment].each do |model|
      entities = model.where(user: source_user)
      migration_logger.info "Model : #{model.to_s}"
      migration_logger.info entities.as_json()
      entities.each do |entity|
        entity.update_columns(user_id: target_user)
       end
    end
    votes = Vote.where(user: source_user)
    migration_logger.info "Model : #{Vote.to_s}"
    migration_logger.info votes.as_json()
    votes.each do |vote|
      if vote.post.present? and !vote.post.voted_by? target_user
        vote.update_columns(user_id: target_user)
      else
        vote.destroy!
      end
    end
    watches = Watch.where(user: source_user)
    migration_logger.info "Model : #{Watch.to_s}"
    migration_logger.info watches.as_json()
    watches.each do |watch|
      if watch.issue.present? and !watch.issue.watched_by? target_user
        watch.update_columns(user_id: target_user)
      else
        watch.destroy!
      end
    end
    source_user.destroy!
  end

  def migration_logger()
    @@migration_logger ||= Logger.new("#{Rails.root}/log/#{@source_nickname}_#{@target_nickname}_#{DateTime.now.to_s(:number)}.log")
  end
end
