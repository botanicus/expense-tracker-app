# This is an INTEGRATION test. If the server
# ain't running, the test ain't gonna work.

require 'spec_helper'
require 'expenses-tracker/models' # So we can create the damn user.

describe 'Sessions endpoint' do
  data = {
    username: 'botanicus',
    password: '123456789'
  }

  context 'Given user exists' do
    describe 'POST /api/sessions', data: data.to_json do
      before(:each) do
        ExpensesTracker::User.create!(
          username: 'botanicus',
          password: '123456789',
          password_confirmation: '123456789')
      end

      it 'returns HTTP 201 created' do
        expect(response.status).to eq(201)
      end

      it 'responds with JSON content type' do
        expect(response.headers['Content-Type']).to match('application/json')
      end

      it 'returns the JWT token' do
        data = JSON.parse(response.body.readpartial)
        expect(data['token']).not_to be_nil
      end
    end
  end

  shared_examples 'bad request' do
    it 'fails with HTTP 400 bad request' do
      expect(response.status).to eq(400)
    end

    it 'responds with JSON content type' do
      expect(response.headers['Content-Type']).to match('application/json')
    end
  end

  context 'Impartial data' do
    impartial_data = data.select { |key, _| key == :password }

    describe 'POST /api/sessions', data: impartial_data.to_json do
      it_behaves_like 'bad request'

      it 'reports that the username/password combination is invalid' do
        data = JSON.parse(response.body.readpartial)
        expect(data['message']).to match(/Invalid username\/password combination/)
      end
    end
  end

  context 'Invalid JSON' do
    describe 'POST /api/sessions', data: '' do
      it_behaves_like 'bad request'

      it 'reports that the JSON is invalid' do
        user = JSON.parse(response.body.readpartial)
        expect(user['message']).to match(/contain two octets/)
      end
    end

    describe 'POST /api/sessions', data: '{' do
      it_behaves_like 'bad request'

      it 'reports that the JSON is invalid' do
        user = JSON.parse(response.body.readpartial)
        expect(user['message']).to match(/contain two octets/)
      end
    end
  end
end
