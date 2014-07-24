#!/usr/bin/env bundle exec rackup -s thin -p 5000

# NOTE: This shebang works only on OS X, not
# on Linux, if you wonder what the hell am I
# doing, it's just matter of convenience.

require 'sinatra'
require 'json'
require 'jwt'

# I extracted those middlewares from this project.
require 'rack-jwt-token-auth'
require 'rack-parse-posted-json'

require_relative './lib/expenses-tracker'

# Default to JSON.
before do
  content_type :json
end

helpers do
  def ensure_authentication
    env['user'] || raise(ExpensesTracker::AuthenticationError.new)
  rescue ExpensesTracker::AuthenticationError => error
    halt(401, {message: error}.to_json)
  end

  # Actually in Sinatra we can do throw :halt or something
  # and hence avoid the need for blocks.
  def ensure_expense_ownership(id, user)
    expense = ExpensesTracker::Expense[id]
    expense || raise(ExpensesTracker::NotFoundError.new("Expense ID=#{id}"))
    return expense if expense.user == user

    # This happens only if we have a bug in our code
    # or the user is tampering with the app.
    halt(403, 'This is not your expense!')
  rescue ExpensesTracker::NotFoundError => error
    halt(404, error.message)
  end
end

# Sign-up. Open to everyone.
#
# Normally you'd want to have some email confirmation,
# but it's not part of the spec and I feel lazy :)
#
# Also it'd be nice to add protection against robots.
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
    token = JWT.encode({username: user.username}, ExpensesTracker::JWT_SECRET)

    # With token-based authentication, there's
    # no such thing as sessions. Hence we're not
    # really creating anything, hence HTTP 200.
    status 200; {token: token}.to_json
  rescue ExpensesTracker::UnauthenticatedUser => error
    halt(400, {message: error.message}.to_json)
  end
end

get '/api/expenses' do
  user = ensure_authentication
  user.expenses.to_a.to_json
end

post '/api/expenses' do
  user = ensure_authentication
  data = env['json'].merge(user: user)
  expense = ExpensesTracker::Expense.create(data)
  user.expenses.add(expense)

  status 201; expense.to_json
end

get '/api/expenses/:id' do
  user = ensure_authentication|
  expense = ensure_expense_ownership(params[:id], user)
  expense.to_json
end

put '/api/expenses/:id' do
  user = ensure_authentication
  expense = ensure_expense_ownership(params[:id], user)
  expense.update_attributes(env['json'])
  expense.save.to_json
end

delete '/api/expenses/:id' do
  user = ensure_authentication
  expense = ensure_expense_ownership(params[:id], user)
  expense.delete
  user.expenses.delete(expense)
  status 204
end

get '/api/weekly-totals' do
  user = ensure_authentication
  weeks = user.expenses.group_by do |expense|
    (expense.created_at.yday / 7) + 1
  end

  weeks.reduce(Hash.new) do |totals, (week_number, expenses)|
    sum = expenses.reduce(0.0) do |sum, expense|
      sum + expense.price
    end

    totals.merge(week_number => {
      sum: sum, avg: sum / expenses.count,
      expenses: expenses
    })
  end.to_json
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

# The Rack app.
use Rack::JWTAuthMiddleware do |token|
  data = JWT.decode(token, ExpensesTracker::JWT_SECRET)[0]
  ExpensesTracker::User.with(:username, data['username'])
end

use Rack::ParsePostedJSON

run Sinatra::Application
