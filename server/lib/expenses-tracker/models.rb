require 'ohm'
require 'bcrypt'

module ExpensesTracker
  class User < Ohm::Model
    # Public attributes.
    attribute :username
    index :username
    unique :username

    # Private attributes.
    attribute :salt
    attribute :encrypted_password

    def self.authenticate(username, password)
      if user = self.with(:username, username)
        encrypted_password = BCrypt::Engine.hash_secret(password, user.salt)
        user if user.encrypted_password == encrypted_password
      end
    end

    def password=(password)
      self.salt = BCrypt::Engine.generate_salt
      self.encrypted_password = begin
        BCrypt::Engine.hash_secret(password, self.salt)
      end
    end
  end
end
