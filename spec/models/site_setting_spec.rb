require 'rails_helper'

RSpec.describe SiteSetting, type: :model do
  subject { SiteSetting.new(key: 'test', value: 'test') }

  describe 'validations' do
    it { should validate_presence_of(:key) }
    it { should validate_uniqueness_of(:key) }
    it { should validate_presence_of(:value) }
  end

  describe '.get' do
    it 'returns the value for an existing setting' do
      SiteSetting.create!(key: 'test_key', value: 'test_value')
      expect(SiteSetting.get('test_key')).to eq('test_value')
    end

    it 'returns default value for non-existent setting' do
      expect(SiteSetting.get('non_existent', default: 'default')).to eq('default')
    end

    it 'returns nil for non-existent setting without default' do
      expect(SiteSetting.get('non_existent')).to be_nil
    end
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

  describe '.enabled?' do
    it 'returns true when value is "true"' do
      SiteSetting.create!(key: 'feature', value: 'true')
      expect(SiteSetting.enabled?('feature')).to be true
    end

    it 'returns false when value is "false"' do
      SiteSetting.create!(key: 'feature', value: 'false')
      expect(SiteSetting.enabled?('feature')).to be false
    end

    it 'returns false when setting does not exist' do
      expect(SiteSetting.enabled?('non_existent')).to be false
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
