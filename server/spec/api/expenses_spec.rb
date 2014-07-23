# This is an INTEGRATION test. If the server
# ain't running, the test ain't gonna work.

require 'spec_helper'
require 'expenses-tracker/models' # So we can create the damn user.
require 'jwt'

describe 'Expenses endpoint' do
  secret = 'bdd4bb20838e6156f54054399434783c'
  token  = JWT.encode({username: 'botanicus'}, secret)

  hdrs = {Authorization: %Q(JWT token="#{token}")}
  data = {title: '小笼包', price: 12.50}

  context 'Authorization header not provided' do
    shared_examples 'unauthorised request' do
      it 'returns HTTP 401 unauthorised' do
        expect(response.status).to eq(401)
      end

      it 'returns JSON body with an explanation' do
        data = JSON.parse(response.body.readpartial)
        expect(data['message']).to eq('No Authorization header provided.')
      end
    end

    describe 'GET /api/expenses' do
      it_behaves_like 'unauthorised request'
    end

    describe 'POST /api/expenses', data: data.to_json do
      it_behaves_like 'unauthorised request'
    end

    describe 'GET /api/expenses/1' do
      it_behaves_like 'unauthorised request'
    end

    describe 'DELETE /api/expenses/1' do
      it_behaves_like 'unauthorised request'
    end

    describe 'PUT /api/expenses/1', data: data.to_json do
      it_behaves_like 'unauthorised request'
    end
  end

  context 'Authorization header provided' do
    describe 'POST /api/expenses', data: data.to_json, headers: hdrs do
      before(:each) do
        ExpensesTracker::User.create!(
          username: 'botanicus',
          password: '123456789',
          passwordConfirmation: '123456789')
      end

      it 'returns HTTP 201 created' do
        expect(response.status).to eq(201)
      end

      it 'responds with JSON content type' do
        expect(response.headers['Content-Type']).to match('application/json')
      end

      it 'returns the newly created resource' do
        data = JSON.parse(response.body.readpartial)
        expect(data.keys.sort).to eq(['price', 'title'])
        expect(data['title']).to eq('小笼包')
        expect(data['price']).to eq(12.50)
      end
    end
  end
end
