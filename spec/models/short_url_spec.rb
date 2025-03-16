require 'rails_helper'

RSpec.describe ShortUrl, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      short_url = build(:short_url)
      expect(short_url).to be_valid
    end

    it 'is invalid without original_url' do
      short_url = build(:short_url, original_url: nil)
      expect(short_url).not_to be_valid
      expect(short_url.errors[:original_url]).to include("can't be blank")
    end

    it 'is invalid with invalid original_url format' do
      short_url = build(:short_url, original_url: 'test')
      expect(short_url).not_to be_valid
      expect(short_url.errors[:original_url]).to include('is invalid')
    end

    it 'is invalid with duplicate short_code' do
      create(:short_url, short_code: 'ABC123')
      duplicate = build(:short_url, short_code: 'ABC123')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:short_code]).to include('has already been taken')
    end
  end

  describe '#expired?' do
    it 'returns false if expired_at is nil' do
      short_url = build(:short_url, expired_at: nil)
      expect(short_url.expired?).to be false
    end

    it 'returns false if expired_at is in the future' do
      short_url = build(:short_url, expired_at: 1.hour.from_now)
      expect(short_url.expired?).to be false
    end

    it 'returns true if expired_at is in the past' do
      short_url = build(:short_url, :expired)
      expect(short_url.expired?).to be true
    end
  end

  describe 'before_validation' do
    it 'generates short_code if not provided' do
      short_url = create(:short_url, short_code: nil)
      expect(short_url.short_code).to be_present
      expect(short_url.short_code).is_a?(String)
    end

    it 'keeps custom short_code if provided' do
      short_url = create(:short_url, short_code: 'test')
      expect(short_url.short_code).to eq('test')
    end
  end
end
