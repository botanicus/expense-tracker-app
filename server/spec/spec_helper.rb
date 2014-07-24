require 'rspec-sane-http'
require 'redic' # Ohm uses this.

require 'pry'

RSpec.configure do |config|
  config.extend(HttpApi::Extensions)

  config.add_setting(:base_url)
  config.base_url = 'http://localhost:5000'

  redis = Redic.new
  config.after(:each) do
    redis.call(:flushdb)
  end
end

shared_examples 'unauthorised request' do
  it 'returns HTTP 401 unauthorised' do
    expect(response.status).to eq(401)
  end

  it 'returns JSON body with an explanation' do
    data = JSON.parse(response.body.readpartial)
    expect(data['message']).to eq('No Authorization header provided.')
  end
end

shared_examples 'bad request' do
  it 'fails with HTTP 400 bad request' do
    expect(response.status).to eq(400)
  end

  it 'responds with JSON content type' do
    expect(response.headers['Content-Type']).to match('application/json')
  end

  it 'the error' do
    user = JSON.parse(response.body.readpartial)
    expect(user['message']).not_to be_nil
  end
end
