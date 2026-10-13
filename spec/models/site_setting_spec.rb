require 'rails_helper'

RSpec.describe SiteSetting, type: :model do
  subject { SiteSetting.new(key: 'test', value: 'test') }

  describe 'validations' do
    it { should validate_presence_of(:key) }
    it { should validate_uniqueness_of(:key) }
    it { should validate_presence_of(:value) }
  end

  describe '.set' do
    it 'creates a new setting' do
      SiteSetting.set('new_key', 'new_value')
      expect(SiteSetting.find_by(key: 'new_key').value).to eq('new_value')
    end

    it 'updates an existing setting' do
      SiteSetting.create!(key: 'existing_key', value: 'old_value')
      SiteSetting.set('existing_key', 'new_value')
      expect(SiteSetting.find_by(key: 'existing_key').value).to eq('new_value')
    end
  end

  describe '.registration_enabled?' do
    it 'returns true when registration is enabled' do
      SiteSetting.set(:registration_enabled, 'true')
      expect(SiteSetting.registration_enabled?).to be true
    end

    it 'returns false when registration is disabled' do
      SiteSetting.set(:registration_enabled, 'false')
      expect(SiteSetting.registration_enabled?).to be false
    end

    it 'returns true by default' do
      expect(SiteSetting.registration_enabled?).to be true
    end
  end
end
