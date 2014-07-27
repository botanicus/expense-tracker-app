require 'ohm'
require 'ohm/contrib'
require 'ohm/validations'

require 'bcrypt'

module ExpensesTracker
  module ErrorAsJSON
    def to_json
      {message: self.message}.to_json
    end
  end

  class InvalidObject < StandardError
    include ErrorAsJSON


    def initialize(errors)
      super("Object is invalid: #{errors.inspect}.")
    end
  end

  class UndefinedAttribute < StandardError
    include ErrorAsJSON

    def initialize(error)
      match = error.message.match(/undefined method `(.+)='/)
      super("Attribute '#{match[1]}' doesn't exist.")
    end
  end

  class UnauthenticatedUser < StandardError
    include ErrorAsJSON

    def initialize(username)
      super("Invalid username/password combination for user #{username}.")
    end
  end

  class Model < Ohm::Model
    def initialize(*args)
      super(*args)
    rescue Exception => error
      # C'mon guys, how about providing a special error class?
      raise UndefinedAttribute.new(error)
    end

    def self.create!(*args)
      self.new(*args).tap(&:save!)
    end

    def save!
      unless self.save
        raise InvalidObject.new(self.errors)
      end
    end
  end

  class Expense < Model
    include Ohm::Validations
    include Ohm::Timestamps

    attribute :title

    # Price is float. Terrible idea, I know.
    # In real-world app I'd do price * 100
    # and save the price in pennies. #lazy
    attribute :price, lambda { |value| value.to_f }
    attribute :comment

    reference :user, 'ExpensesTracker::User'

    def to_json(*)
      {
        id: self.id, title: self.title, price: self.price,
        comment: self.comment, createdAt: self.created_at
      }.to_json
    rescue Ohm::MissingID
      {
        title: self.title, price: self.price, comment: self.comment
      }.to_json
    end
  end

  class User < Model
    include Ohm::Validations
    include Ohm::Timestamps

    # Public attributes.
    attr_accessor :password, :passwordConfirmation

    attribute :username
    index :username
    unique :username

    set :expenses, 'ExpensesTracker::Expense'

    def validate
      assert_present(:username)

      if self.password != self.passwordConfirmation
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

    def self.authenticate!(username, password)
      user = self.authenticate(username, password)
      raise UnauthenticatedUser.new(username) unless user
      return user
    end

    # Hooks.
    def save
      self.encrypt_password
      super if self.valid?
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
