class DeviseCreateUsers < ActiveRecord::Migration
  def up
    rename_table :users, :old_users

    create_table(:users) do |t|
      ## Database authenticatable
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      # t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      # t.string   :unlock_token # Only if unlock strategy is :email or :both
      # t.datetime :locked_at

      ## Profile
      t.string :nickname,           null: false
      t.string :image,              null: true

      t.timestamps null: false
    end

    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :confirmation_token,   unique: true
    # add_index :users, :unlock_token,         unique: true

    add_index :users, :nickname,             unique: true

    password = '12345678'
    new_hashed_password = User.new(password: password).encrypted_password

    result = ActiveRecord::Base.connection.execute "SELECT nickname, email, id, created_at, updated_at FROM old_users"
    result.each do |row|
      if (Rails.env.production? or Rails.env.staging?)
        nickname = row[0]
        email = row[1]
        id = row[2]
        created_at = row[3].to_s(:db)
        updated_at = row[4].to_s(:db)
      else
        nickname = row['nickname']
        email = row['email']
        id = row['id']
        created_at = row['created_at']
        updated_at = row['updated_at']
      end
      confirmed_at = DateTime.now.to_s(:db)
      query = "INSERT INTO
        users (id, email, encrypted_password, nickname, created_at, updated_at, confirmed_at)
        VALUES(#{id}, '#{email}', '#{new_hashed_password}', '#{nickname}', '#{created_at}', '#{updated_at}', '#{confirmed_at}')"
      ActiveRecord::Base.connection.execute query
      say query
    end
  end

  def down
    raise "unimplemented"
  end
end
