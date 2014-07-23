#!/usr/bin/env rackup -s thin -p 5000

# NOTE: This shebang works only on OS X, not
# on Linux, if you wonder what the hell am I
# doing, it's just matter of convenience.

require 'sinatra'
require 'json'
require 'jwt'

require_relative './lib/expenses-tracker/models'
require_relative './lib/expenses-tracker/middlewares'

class AuthenticationError < StandardError
  def initialize
    super('No Authorization header provided.')
  end
end

# REST API.
JWT_SECRET = 'bdd4bb20838e6156f54054399434783c'

# Default to JSON.
before do
  content_type :json
end

set :sessions, false

helpers do
  def authenticate(&block)
    env['user'] || raise(AuthenticationError.new)
    block.call(env['user'])
  rescue AuthenticationError => error
    status 401; {message: error}.to_json
  end

  def ensure_expense_authorship(id, user, &block)
    expense = ExpensesTracker::Expense.get(params[:id])
    if expense.user == user
      block.call(expense)
    else
      # This happens only if we have a bug in our code
      # or the user is tampering with the app.
      status 403; 'This is not your expense!'
    end
  end
end

# Sign-up. Open to everyone.
#
# Normally you'd want to have some email confirmation,
# but it's not part of the spec and I feel lazy :)
post '/api/users' do
  begin
    user = ExpensesTracker::User.create!(env['json'])
    status 201; user.to_json
  rescue ExpensesTracker::InvalidObject,
         ExpensesTracker::UndefinedAttribute => error
    status 400; {message: error.message}.to_json
  end
end

post '/api/username-check' do
  name = env['json']['username']
  user = ExpensesTracker::User.with(:username, name)
  status 200; {available: ! user}.to_json
end

post '/api/sessions' do
  begin
    user  = ExpensesTracker::User.authenticate!(
      *env['json'].values_at('username', 'password'))

    # We might want to use iat and exp claims for expiration.
    # http://www.intridea.com/blog/2013/11/7/json-web-token-the-useful-little-standard-you-haven-t-heard-about
    token = JWT.encode({username: user.username}, JWT_SECRET)

    # With token-based authentication, there's
    # no such thing as sessions. Hence we're not
    # really creating anything, hence HTTP 200.
    status 200; {token: token}.to_json
  rescue ExpensesTracker::UnauthenticatedUser => error
    status 400; {message: error.message}.to_json
  end
end

get '/api/expenses' do
  authenticate do |user|
    user.expenses.to_a.to_json
  end
end

post '/api/expenses' do
  authenticate do |user|
    expense = ExpensesTracker::Expense.create(env['json'])
    user.expenses.add(expense)

    status 201; expense.to_json
  end
end

get '/api/expenses/:id' do
  authenticate do |user|
    ensure_expense_authorship(params[:id], user) do |expense|
      expense.to_json
    end
  end
end

put '/api/expenses/:id' do
  authenticate do |user|
    ensure_expense_authorship(params[:id], user) do |expense|
      expense.update_attributes(env['json'])
      expense.to_json
    end
  end
end

delete '/api/expenses/:id' do
  authenticate do |user|
    ensure_expense_authorship(params[:id], user) do |expense|
      expense.destroy
      status 204
    end
  end
end

# Error handlers.
not_found do
  # This would OBVIOUSLY be handled by Nginx.
  # This serves for convenience purpose only.
  # For a real project, I'd use Vagrant and test
  # my Nginx vhosts as part of the development
  # process. Here's an example copied from a
  # project I'm working on:
  #
  # server {
  #   listen 80;
  #   server_name app.pay-per-task.com app.pay-per-task.dev;
  #   (some access_log's etc ...)

  #   # This returns HTTP 200 on any
  #   # route and serves build.html.
  #   error_page 404 = /build.html;

  #   location / {
  #     index build.html;
  #     root /webs/ppt/webs/app.pay-per-task.com/content;
  #   }
  # }
  #
  # Also, the API totally SHOULD be on a separate subdomain,
  # but for that we'd need either Vagrant or too much setup
  # on the dev machine.

  status 200

  path = File.expand_path("../../client#{env['PATH_INFO']}", __FILE__)
  if File.file?(path)
    # Hacky hacky! This code would never be part of real
    # app since it'd be handled by Nginx in Vagrant.
    # I know it's terrible.
    content_type path.split('.').last
    File.new(path)
  else
    content_type :html
    File.new(File.expand_path('../../client/app.html', __FILE__))
  end
end


use AuthenticationMiddleware, JWT_SECRET
use ParsePostedJSON

run Sinatra::Application
