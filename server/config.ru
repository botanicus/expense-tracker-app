#!/usr/bin/env rackup -s thin -p 5000

# NOTE: This shebang works only on OS X, not
# on Linux, if you wonder what the hell am I
# doing, it's just matter of convenience.

require 'sinatra'

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
  spa_path = File.expand_path('../../client/app.html', __FILE__)
  File.new(spa_path)
end

run Sinatra::Application
