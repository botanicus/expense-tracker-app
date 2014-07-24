# This is an INTEGRATION test. If the server
# ain't running, the test ain't gonna work.

require 'spec_helper'
require 'expenses-tracker/models' # So we can create the damn user.
require 'jwt'

describe 'Expenses endpoint' do
  secret = 'bdd4bb20838e6156f54054399434783c'
  token  = JWT.encode({username: 'botanicus'}, secret)

  hdrs = {Authorization: %Q(JWT token="#{token}")}
  data = {title: '小笼包', price: 12.50, comment: 'Very yummy!'}

  context 'Authorization header not provided' do
  end
end
