User.seed_once(:email) do |u|
  u.email = u.uid = 'account@parti.xyz'
  u.provider = 'email'
  u.encrypted_password = User.new.send(:password_digest, ENV["PARTI_ADMIN_PASSWORD"])
  u.nickname = 'parti'
  u.confirmed_at = DateTime.current
end
