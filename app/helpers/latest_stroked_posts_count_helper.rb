module LatestStrokedPostsCountHelper
  @@stroked_count_redis_config = YAML.load_file(Rails.root + 'config/redis.yml')[Rails.env]

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
      Moneta.new(:Redis, host: @@stroked_count_redis_config['host'], port: @@stroked_count_redis_config['port'])
    else
      Moneta.new(:File, dir: 'moneta')
    end
  end
end
