# This is an INTEGRATION test. If the server
# ain't running, the test ain't gonna work.

require 'spec_helper'
require 'expenses-tracker/models' # So we can create the user.
require 'jwt'

describe 'Expenses endpoint' do
  secret = 'bdd4bb20838e6156f54054399434783c'
  token  = JWT.encode({username: 'botanicus'}, secret)

  headers = {Authorization: %Q(JWT token="#{token}")}
  rq_data = {title: '小笼包', price: 12.50, comment: 'Very yummy!'}

  context 'Authorization header not provided' do
    describe 'GET /api/expenses' do
      it_behaves_like 'unauthorised request'
    end

    describe 'POST /api/expenses', data: rq_data.to_json do
      it_behaves_like 'unauthorised request'
    end

    describe 'GET /api/expenses/1' do
      it_behaves_like 'unauthorised request'
    end

    describe 'DELETE /api/expenses/1' do
      it_behaves_like 'unauthorised request'
    end

    describe 'PUT /api/expenses/1', data: rq_data.to_json do
      it_behaves_like 'unauthorised request'
    end
  end

  context 'Authorization header provided' do
    before(:each) do
      @user = ExpensesTracker::User.create!(
        username: 'botanicus',
        password: '123456789',
        passwordConfirmation: '123456789')
    end

    context 'incomplete data' do
      describe 'POST /api/expenses', data: {comment: ''}.to_json, headers: headers do
        it 'returns HTTP 400 bad request' do
          expect(response.status).to eq(400)
        end

        it 'responds with JSON content type' do
          expect(response.headers['Content-Type']).to match('application/json')
        end

        it 'returns validation errors' do
          data = JSON.parse(response.body.readpartial)
          expect(data['message']).to eq('INVALID')
        end
      end
    end

    context 'valid data' do
      describe 'POST /api/expenses', data: rq_data.to_json, headers: headers do
        it 'returns HTTP 201 created' do
          expect(response.status).to eq(201)
        end

        it 'responds with JSON content type' do
          expect(response.headers['Content-Type']).to match('application/json')
        end

        it 'returns the newly created resource' do
          data = JSON.parse(response.body.readpartial)
          expect(data.keys.sort).to eq(['comment', 'createdAt', 'id', 'price', 'title'])
          expect(data['title']).to eq('小笼包')
          expect(data['price']).to eq(12.50)
        end
      end
    end

    describe 'GET /api/expenses', headers: headers do
      it 'returns an empty collection if there are none' do
        data = JSON.parse(response.body.readpartial)
        expect(data).to be_empty
      end

      it 'returns collection of expenses if there are some' do
        POST('/api/expenses', headers, rq_data)

        data = JSON.parse(response.body.readpartial)
        expect(data.length).to eq(1)
        expect(data[0].keys.sort).to eq(['comment', 'createdAt', 'id', 'price', 'title'])
      end
    end

    describe 'GET /api/expenses/1', headers: headers do
      it 'returns given expense' do
        POST('/api/expenses', headers, rq_data)

        data = JSON.parse(response.body.readpartial)
        expect(data.keys.sort).to eq(['comment', 'createdAt', 'id', 'price', 'title'])
      end
    end

    describe 'PUT /api/expenses/1', headers: headers, data: rq_data.to_json do
      it 'updates given expense' do
        POST('/api/expenses', headers, rq_data.merge(title: 'Xiao long bao'))

        response # Fire the request.

        data = GET('/api/expenses/1', headers)
        expect(data['title']).to eq('小笼包')
      end

      it 'returns the updated data' do
        POST('/api/expenses', headers, rq_data)

        data = JSON.parse(response.body.readpartial)
        expect(data['title']).to eq('小笼包')
      end
    end

    describe 'DELETE /api/expenses/1', headers: headers do
      it 'deletes given expense' do
        POST('/api/expenses', headers, rq_data)

        expect(response.code).to eq(204)
      end
    end
  end
end
