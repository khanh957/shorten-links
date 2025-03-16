require 'rails_helper'

RSpec.describe CleanExpiredShortUrlsJob, type: :job do
  let!(:expired_short_url) { ShortUrl.create!(original_url: 'https://example1.com', expired_at: 2.months.ago) }
  let!(:valid_short_url) { ShortUrl.create!(original_url: 'https://example2.com', expired_at: 1.day.from_now) }

  before do
    Sidekiq::Testing.inline!
    $redis.set(expired_short_url.short_code, expired_short_url.original_url)
  end

  it "remove links that have expired more than 1 month" do
    expect { CleanExpiredShortUrlsJob.perform_now }
      .to change { ShortUrl.count }.by(-1)
  end

  it "is not remove links that have not expired more than 1 month" do
    CleanExpiredShortUrlsJob.perform_now
    expect(ShortUrl.first.original_url).to eq(valid_short_url.original_url)
  end

  it "remove short code from Redis" do
    CleanExpiredShortUrlsJob.perform_now
    expect($redis.get(expired_short_url.short_code)).to be_nil
  end

  it "enqueue job into the queue" do
    expect {
      CleanExpiredShortUrlsJob.perform_later
    }.to have_enqueued_job(CleanExpiredShortUrlsJob)
  end
end
