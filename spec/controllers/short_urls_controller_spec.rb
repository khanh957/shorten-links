require 'rails_helper'

RSpec.describe ShortUrlsController, type: :controller do
  describe 'POST #encode' do
    context 'with valid params' do
      let(:valid_params) do
        { short_url: { original_url: 'https://example.com' } }
      end

      it 'creates a new short_url and returns the shortened URL' do
        post :encode, params: valid_params, format: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['short_url']).to match(%r{http://test.host/[A-Za-z0-9_-]{6}})
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
    it 'returns original_url for valid short URL' do
      create(:short_url, original_url: 'https://example.com', short_code: 'test123')
      post :decode, params: { url: 'http://test.host/test123' }, format: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['original_url']).to eq('https://example.com')
    end

    it 'returns error for expired short URL' do
      create(:short_url, :expired, short_code: 'Expired')
      post :decode, params: { url: 'http://test.host/Expired' }, format: :json
      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Short URL has expired')
    end

    it 'returns error for non-existent short URL' do
      post :decode, params: { url: 'http://test.host/NonExist' }, format: :json
      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Short URL not found')
    end
  end

  describe 'GET #redirect' do
    it 'redirects to original_url for valid short_code' do
      create(:short_url, original_url: 'https://example.com', short_code: 'test123')
      get :redirect, params: { short_code: 'test123' }
      expect(response).to redirect_to('https://example.com')
    end

    it 'returns error for expired short_code' do
      create(:short_url, :expired, short_code: 'Expired')
      get :redirect, params: { short_code: 'Expired' }
      expect(response).to have_http_status(:bad_request)
      expect(response.body).to eq('Short URL has expired')
    end

    it 'returns error for non-existent short_code' do
      get :redirect, params: { short_code: 'NonExist' }
      expect(response).to have_http_status(:not_found)
      expect(response.body).to eq('Short URL not found')
    end
  end
end
