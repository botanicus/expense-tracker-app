require 'spec_helper'

# This is an INTEGRATION test. If the server
# ain't running, the test ain't gonna work.
#
# This is not a typical way people usually
# write tests in Ruby. I'm a strong believer
# in integration tests though. I'm very pleased
# that you guys included it as a requirement!

shared_examples 'single page app route' do
  it 'returns HTTP 200 OK' do
    expect(response.status).to eq(200)
  end

  it 'serves HTML content type' do
    expect(response.headers['Content-Type']).to eq('text/html;charset=utf-8')
  end

  it 'serves app.html' do
    expect(response.body.readpartial).to match(/Expenses Tracker/)
  end
end

describe 'GET /' do
  it_behaves_like 'single page app route'
end

describe 'GET /randompage345' do
  it_behaves_like 'single page app route'
end

describe 'GET /a/b/c/d/randompage345' do
  it_behaves_like 'single page app route'
end
