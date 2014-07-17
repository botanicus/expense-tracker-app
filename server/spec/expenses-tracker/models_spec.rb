require 'spec_helper'
require 'expenses-tracker/models'

describe ExpensesTracker::User do
  it 'has a username attribute' do
    subject.username = 'botanicus'
    expect(subject.username).to eq('botanicus')
  end

  it 'is not possible to save multiple users under the same username' do
    described_class.create(username: 'botanicus')
  end

  context 'authentication' do
    before(:each) do
      subject.username = 'botanicus'
      subject.password = '123456789'
      subject.save
    end

    it 'is possible to log in with valid credentials' do
      user = described_class.authenticate('botanicus', '123456789')
      expect(user).not_to be_nil
    end

    it 'is not possible to log in with invalid credentials' do
      user = described_class.authenticate('botanicus', '987654321')
      expect(user).to be_nil
    end

    it 'is not possible to log in if you are not registered' do
      user = described_class.authenticate('johndoe', '987654321')
      expect(user).to be_nil
    end
  end

  after(:each) do
    ExpensesTracker::User.redis.call(:flushdb)
  end
end
