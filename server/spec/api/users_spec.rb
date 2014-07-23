# This is an INTEGRATION test. If the server
# ain't running, the test ain't gonna work.
#
# This is not a typical way people usually
# write tests in Ruby. I'm a strong believer
# in integration tests though. I'm very pleased
# that you guys included it as a requirement!

require 'spec_helper'

describe 'Users endpoint' do
  data = {
    username: 'botanicus',
    password: '12345',
    passwordConfirmation: '12345'
  }

  describe 'POST /api/users', data: data.to_json do
    it 'returns HTTP 201 created' do
      expect(response.status).to eq(201)
    end

    it 'responds with JSON content type' do
      expect(response.headers['Content-Type']).to match('application/json')
    end

    it 'returns the newly created user record (public attrs only)' do
      user = JSON.parse(response.body.readpartial)
      expect(user.keys.sort).to eq(['username'])
      expect(user['username']).to eq('botanicus')
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

  context 'Impartial data' do
    impartial_data = data.reject { |key, _| key == :passwordConfirmation }

    describe 'POST /api/users', data: impartial_data.to_json do
      it_behaves_like 'bad request'

      it 'reports that the object is invalid' do
        user = JSON.parse(response.body.readpartial)
        expect(user['message']).to match(/Object is invalid/)
      end
    end
  end

  context 'Invalid JSON' do
    describe 'POST /api/users', data: '' do
      it_behaves_like 'bad request'

      it 'reports that the JSON is invalid' do
        user = JSON.parse(response.body.readpartial)
        expect(user['message']).to match(/contain two octets/)
      end
    end
  end

  context 'Extra attributes' do
    describe 'POST /api/users', data: {a: 1}.to_json do
      it_behaves_like 'bad request'

      it 'reports that attribute a is missing' do
        user = JSON.parse(response.body.readpartial)
        expect(user['message']).to match(/Attribute 'a' doesn't exist/)
      end
    end

    describe 'POST /api/users', data: '{' do
      it_behaves_like 'bad request'

      it 'reports that the JSON is invalid' do
        user = JSON.parse(response.body.readpartial)
        expect(user['message']).to match(/contain two octets/)
      end
    end
  end
end
