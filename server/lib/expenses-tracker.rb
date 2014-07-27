module ExpensesTracker
  class AuthenticationError < StandardError
    MESSAGE = 'User either does not exist or no authorization header was provided.'
    def initialize
      super(self.class::MESSAGE)
    end
  end

  class NotFoundError < StandardError
    def initialize(what)
      super("#{what} doesn't exist.")
    end
  end

  JWT_SECRET = 'bdd4bb20838e6156f54054399434783c'
end

require_relative 'expenses-tracker/models'
