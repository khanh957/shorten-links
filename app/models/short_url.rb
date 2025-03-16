class ShortUrl < ApplicationRecord
  validates :original_url, presence: true, format: URI::regexp(%w[http https])
  validates :short_code, presence: true, uniqueness: true
  before_validation :generate_short_code, if: -> { short_code.blank? }

  scope :active, -> { where(expired_at: nil).or(where('expired_at > ?', Time.current)) }

  def expired?
    expired_at.present? && expired_at < Time.current
  end

  private

  def generate_short_code
    random_number = SecureRandom.random_number(1000000000)
    max_id = ShortUrl.maximum(:id).to_i rescue 0
    combined_number = max_id * 1000000000 + random_number
    
    self.short_code = Base62.encode(combined_number)
  rescue ActiveRecord::RecordNotUnique
    retry
  end
end
