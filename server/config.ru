#!/usr/bin/env rackup -s thin -p 5000

# NOTE: This shebang works only on OS X, not
# on Linux, if you wonder what the hell am I
# doing, it's just matter of convenience.

require 'sinatra'
require 'json'
require 'jwt'

require_relative './lib/expenses-tracker/models'

# REST API.
JWT_SECRET = 'bdd4bb20838e6156f54054399434783c'

# Default to JSON.
before do
  content_type :json
end

# Sign-up. Open to everyone.
#
# Normally you'd want to have some email confirmation,
# but it's not part of the spec and I feel lazy :)
post '/api/users' do
  begin
    data = JSON.parse(env['rack.input'].read)
    user = ExpensesTracker::User.create!(data)
    status 201; user.to_json
  rescue ExpensesTracker::InvalidObject,
         ExpensesTracker::UndefinedAttribute,
         JSON::ParserError => error
    status 400; {message: error.message}.to_json
  end
end

post '/api/username-check' do
  begin
    data = JSON.parse(env['rack.input'].read)
    user = ExpensesTracker::User.with(:username, data['username'])
    status 200; {available: ! user}.to_json
  rescue JSON::ParserError => error
    status 400; {message: error.message}.to_json
  end
end

post '/api/sessions' do
  begin
    data  = JSON.parse(env['rack.input'].read)
    user  = ExpensesTracker::User.authenticate!(
      *data.values_at('username', 'password'))

    token = JWT.encode({username: user.username}, JWT_SECRET)

    # With token-based authentication, there's
    # no such thing as sessions. Hence we're not
    # really creating anything, hence HTTP 200.
    status 200; {token: token}.to_json
  rescue ExpensesTracker::UnauthenticatedUser,
         JSON::ParserError => error
    status 400; {message: error.message}.to_json
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

run Sinatra::Application
