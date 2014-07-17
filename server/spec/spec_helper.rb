require 'rspec-sane-http'
require 'redic' # Ohm uses this.

require 'pry'

RSpec.configure do |config|
  config.extend(HttpApi::Extensions)

  config.add_setting(:base_url)
  config.base_url = 'http://localhost:5000/'

  redis = Redic.new
  config.after(:each) do
    redis.call(:flushdb)
  end
end
