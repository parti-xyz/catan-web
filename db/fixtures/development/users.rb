User.seed_once(:email) do |u|
  u.email = u.uid = 'admin@test.com'
  u.provider = 'email'
  u.encrypted_password = User.new.send(:password_digest, "12345678")
  u.nickname = 'admin'
  u.confirmed_at = 5.day.ago.to_s(:db)
end
