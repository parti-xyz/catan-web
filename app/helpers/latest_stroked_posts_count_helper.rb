module LatestStrokedPostsCountHelper
  def self.current_version
    store = Moneta.new(:File, dir: 'moneta')
    return store['last_stroked_version']
  ensure
    store.try(:close)
  end

  def self.set_version(version)
    store = Moneta.new(:File, dir: 'moneta')
    store['last_stroked_version'] = version
  ensure
    store.try(:close)
  end
end
