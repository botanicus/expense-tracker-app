module ExpensesTracker
  class AuthenticationError < StandardError
    def initialize
      super('No Authorization header provided.')
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
require_relative 'expenses-tracker/middlewares'
