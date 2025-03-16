class CleanExpiredShortUrlsJob < ApplicationJob
  queue_as :default

  def perform
    expired_links = ShortUrl.where("expired_at < ?", 1.month.ago)
    
    expired_links.find_each do |short_url|
      $redis.del(short_url.short_code)
      short_url.destroy
    end
  end
end
