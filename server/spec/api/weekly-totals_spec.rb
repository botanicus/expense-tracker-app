# This is an INTEGRATION test. If the server
# ain't running, the test ain't gonna work.

require 'spec_helper'
require 'expenses-tracker/models' # So we can create the user.
require 'jwt'

describe 'Weekly totals endpoint' do
  secret = 'bdd4bb20838e6156f54054399434783c'
  token  = JWT.encode({username: 'botanicus'}, secret)

  headers = {Authorization: %Q(JWT token="#{token}")}
  rq_data = {title: '小笼包', price: 12.50, comment: 'Very yummy!'}

  context 'Authorization header not provided' do
    describe 'GET /api/weekly-totals' do
      it_behaves_like 'unauthorised request'
    end
  end

  context 'Authorization header provided' do
    before(:each) do
      POST('/api/users', headers,
        username: 'botanicus',
        password: '123456789',
        passwordConfirmation: '123456789')

      3.times do
        POST('/api/expenses', headers, title: '小笼包', price: 5.75)
      end
    end

    describe 'GET /api/weekly-totals', headers: headers do
      it do
        data = JSON.parse(response.body.readpartial)
        expect(data.keys.length).to eq(1)

        this_week = data[data.keys.first]
        expect(this_week['sum']).to eq(17.25)
        expect(this_week['avg']).to eq(2.4642857142857144)

        expect(this_week['expenses'].length).to eq(3)
        expect(this_week['expenses'][0]['title']).to eq('小笼包')
      end
    end
  end
end
