require 'rails_helper'

RSpec.describe ShortUrlsController, type: :controller do
  let(:valid_short_url) { create(:short_url, short_code: 'test123', original_url: 'https://example.com') }
  let(:expired_short_url) { create(:short_url, :expired, short_code: 'code_expired') }

  describe 'POST #encode' do
    context 'with valid params' do
      let(:valid_params) do
        { short_url: { original_url: 'https://example.com' } }
      end

      it 'creates a new short_url and returns the shortened URL' do
        post :encode, params: valid_params, format: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['short_url']).to match(%r{http://test.host/[A-Za-z0-9_-]})
      end

      it 'uses custom_short_code if provided' do
        post :encode, params: { short_url: {original_url: 'https://example.com', custom_short_code: 'custom_link'} }, format: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['short_url']).to eq('http://test.host/custom_link')
      end
    end

    context 'with invalid params' do
      it 'returns an error if url is missing' do
        post :encode, params: { short_url: {original_url: ''} }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to include("can't be blank")
      end

      it 'returns an error if short_code is duplicate' do
        create(:short_url, short_code: 'test123')
        post :encode, params: { short_url: {original_url: 'https://example.com', custom_short_code: 'test123'} }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to include('has already been taken')
      end
    end
  end

  describe 'POST #decode' do
    context 'when URL is cached in Redis' do
      before do
        $redis.set('test123', 'https://example.com')
      end

      it 'returns cached original_url without query database' do
        expect(ShortUrl).not_to receive(:find_by!)
        post :decode, params: { url: 'http://test.host/test123' }, format: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['original_url']).to eq('https://example.com')
      end
    end

    context 'when URL is not cached' do
      it 'fetches from database and caches it' do
        valid_short_url
        post :decode, params: { url: 'http://test.host/test123' }, format: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['original_url']).to eq('https://example.com')
        expect($redis.get('test123')).to eq('https://example.com')
        expect($redis.ttl('test123')).to eq(3600)
      end

      it 'caches with custom TTL if expired_at is set' do
        create(:short_url, short_code: 'Temp123', original_url: 'https://temp.com', expired_at: 2.hours.from_now)
        post :decode, params: { url: 'http://test.host/Temp123' }, format: :json
        expect(response).to have_http_status(:ok)
        ttl = $redis.ttl('Temp123')
        expect(ttl).to be_between(7000, 7200)
      end

      it 'returns error if short_url is expired' do
        expired_short_url
        post :decode, params: { url: 'http://test.host/code_expired' }, format: :json
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Short URL has expired')
      end

      it 'returns error if short_url not found' do
        post :decode, params: { url: 'http://test.host/NonExist' }, format: :json
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Short URL not found')
      end
    end
  end

  describe 'GET #redirect' do
    context 'when URL is cached in Redis' do
      before do
        $redis.set('test123', 'https://example.com')
      end

      it 'redirects to cached URL without hitting database' do
        expect(ShortUrl).not_to receive(:find_by!)
        get :redirect, params: { short_code: 'test123' }
        expect(response).to redirect_to('https://example.com')
        expect(response).to have_http_status(:found)
      end
    end

    context 'when URL is not cached' do
      it 'fetches from database, caches, and redirects' do
        valid_short_url
        get :redirect, params: { short_code: 'test123' }
        expect(response).to redirect_to('https://example.com')
        expect(response).to have_http_status(:found)
        expect($redis.get('test123')).to eq('https://example.com')
        expect($redis.ttl('test123')).to eq(3600)
      end

      it 'returns error if short_url is expired' do
        expired_short_url
        get :redirect, params: { short_code: 'code_expired' }
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to eq('Short URL has expired')
      end

      it 'returns error if short_url not found' do
        get :redirect, params: { short_code: 'wrong_code' }
        expect(response).to have_http_status(:not_found)
        expect(response.body).to eq('Short URL not found')
      end
    end
  end
end
