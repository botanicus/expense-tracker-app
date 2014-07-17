require 'ohm'
require 'ohm/validations'

require 'bcrypt'

module ExpensesTracker
  class InvalidObject < StandardError
    def initialize(errors)
      super("Object is invalid: #{errors.inspect}")
    end
  end

  class User < Ohm::Model
    include Ohm::Validations

    # Public attributes.
    attr_accessor :password, :password_confirmation

    attribute :username
    index :username
    unique :username

    def validate
      assert_present(:username)

      if self.password != self.password_confirmation
        self.errors[:password].push(:not_confirmed) && false
      elsif self.salt.nil? || self.encrypted_password.nil?
        self.errors[:password].push(:not_present) && false
      end
    end

    # Private attributes.
    attribute :salt
    attribute :encrypted_password

    def self.authenticate(username, password)
      if user = self.with(:username, username)
        encrypted_password = BCrypt::Engine.hash_secret(password, user.salt)
        user if user.encrypted_password == encrypted_password
      end
    end

    # Hooks.
    def save
      self.encrypt_password
      super if self.valid?
    end

    # TODO: Extract this when I'll have more model classes.
    def self.create!(*args)
      self.new(*args).save!
    end

    def save!
      unless self.save
        raise InvalidObject.new(self.errors)
      end
    end

    def encrypt_password
      self.salt = BCrypt::Engine.generate_salt
      self.encrypted_password = begin
        BCrypt::Engine.hash_secret(self.password, self.salt)
      end
    end

    def to_json
      {username: self.username}.to_json
    end
  end
end
