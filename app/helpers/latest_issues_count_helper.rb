module LatestIssuesCountHelper
  def self.current_version
    store = current_store
    return store['last_stroked_version'] || 0
  ensure
    store.try(:close)
  end

  def self.set_version(version)
    store = current_store
    store['last_stroked_version'] = version
  ensure
    store.try(:close)
  end

  def self.current_store
    if Rails.env.production?
      Moneta.new(:Redis, host: ENV['REDIS_HOST'], port: ENV['REDIS_PORT'])
    else
      Moneta.new(:File, dir: "#{Rails.root}/moneta")
    end
  end
end
