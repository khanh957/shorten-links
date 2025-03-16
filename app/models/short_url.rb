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
    self.short_code = Nanoid.generate(size: 6)
  rescue ActiveRecord::RecordNotUnique
    retry
  end
end
