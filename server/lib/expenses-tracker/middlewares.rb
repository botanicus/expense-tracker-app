require 'json'
require 'jwt'

module ExpensesTracker
  class AuthenticationMiddleware
    def initialize(app, &decoder)
      @app, @decoder = app, decoder
    end

    def call(env)
      begin
        if env['HTTP_AUTHORIZATION']
          token = env['HTTP_AUTHORIZATION'].match(/JWT token="(.+)"/)[1]
          env['user'] = @decoder.call(token)
        end
      rescue JWT::DecodeError => error
        body = {message: error.message}.to_json

        headers = {
          'Content-Type' => 'application/json',
          'Content-Length' => body.bytesize.to_s
        }

        return [401, headers, [body]]
      end

      @app.call(env)
    end
  end


  class ParsePostedJSON
    METHODS_WITH_BODY = ['POST', 'PUT']

    def initialize(app)
      @app = app
    end

    def call(env)
      begin
        if METHODS_WITH_BODY.include?(env['REQUEST_METHOD'])
          data = env['rack.input'].read
          data.force_encoding('utf-8')
          env['json'] = JSON.parse(data)
        end
      rescue JSON::ParserError => error
        body = {message: error.message}.to_json

        headers = {
          'Content-Type' => 'application/json',
          'Content-Length' => body.bytesize.to_s
        }

        return [400, headers, [body]]
      end

      @app.call(env)
    end
  end
end
