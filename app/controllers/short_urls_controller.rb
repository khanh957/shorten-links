class ShortUrlsController < ApplicationController
  protect_from_forgery with: :null_session, only: [:encode, :decode]

  def encode
    custom_short_code = encode_params[:custom_short_code]
    short_url = ShortUrl.new(encode_params.except(:custom_short_code))
    short_url.short_code = custom_short_code if custom_short_code.present?
    short_url.save!
    render json: { short_url: "#{request.base_url}/#{short_url.short_code}" }, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def decode
    full_url = decode_params[:url]
    unless full_url.start_with?("#{request.base_url}/")
      render json: { error: "Invalid short URL" }, status: :bad_request
      return
    end

    short_code = full_url.sub("#{request.base_url}/", '')
    short_url = ShortUrl.find_by!(short_code: short_code)
    if short_url.expired?
      render json: { error: 'Short URL has expired' }, status: :bad_request
    else
      render json: { original_url: short_url.original_url }, status: :ok
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Short URL not found' }, status: :not_found
  end

  def redirect
    short_url = ShortUrl.find_by!(short_code: params[:short_code])
    if short_url.expired?
      render plain: 'Short URL has expired', status: :bad_request
    else
      redirect_to short_url.original_url, allow_other_host: true
    end
  rescue ActiveRecord::RecordNotFound
    render plain: 'Short URL not found', status: :not_found
  end

  private

  def encode_params
    params.require(:short_url).permit(:original_url, :expired_at, :custom_short_code)
  end

  def decode_params
    params.permit(:url)
  end
end
