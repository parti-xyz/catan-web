ADMIN_NICKNAME = 'parti'

User.seed_once(:email) do |u|
  u.email = u.uid = 'account@parti.coop'
  u.provider = 'email'
  u.encrypted_password = User.new.send(:password_digest, ENV["PARTI_ADMIN_PASSWORD"])
  u.nickname = ADMIN_NICKNAME
  u.confirmed_at = DateTime.current
end

admin = User.find_by(nickname: ADMIN_NICKNAME)
admin.add_role(:admin) unless admin.has_role?(:admin)
