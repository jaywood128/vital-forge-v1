class User < ApplicationRecord
  devise :database_authenticatable, :validatable

  # Associations
  has_many :workouts, dependent: :destroy
  has_one :user_preference, dependent: :destroy
  has_many :weekly_feedbacks, dependent: :destroy

  scope :with_workouts_between, ->(start_date, end_date) {
    joins(:workouts).where(workouts: { workout_date: start_date..end_date }).distinct
  }

  scope :with_workouts_this_week, -> {
    with_workouts_between(1.week.ago.beginning_of_day, Time.current.end_of_day)
  }

  # Delegations
  delegate :primary_goal, :training_days_per_week, to: :user_preference, allow_nil: true

  # Validations
  validates :email,
    presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }

  # Phone number validation (US only for now)
  # Accepts formats: (415) 555-1234, 415-555-1234, 4155551234, +1 415 555 1234
  # Normalizes to E.164 format: +14155551234
  validates :phone_number,
    uniqueness: true,
    allow_nil: true,
    format: {
      with: /\A[\d\s\-\(\)\+]+\z/,
      message: "must contain only digits, spaces, dashes, parentheses, or +"
    },
    length: { minimum: 10, maximum: 20, allow_nil: true }

  validates :first_name, :last_name, presence: true

  # Normalize email and phone number before saving (after validation)
  before_save :normalize_email, :normalize_phone_number

  # Security constants
  MAX_LOGIN_ATTEMPTS = 5
  LOCKOUT_DURATION = 30.minutes

  # Account lockout methods
  def increment_failed_login!
    self.failed_login_attempts += 1
    self.locked_at = Time.current if failed_login_attempts >= MAX_LOGIN_ATTEMPTS
    save(validate: false)
  end

  def reset_failed_login!
    update_columns(failed_login_attempts: 0, locked_at: nil)
  end

  def locked?
    locked_at.present? && locked_at > LOCKOUT_DURATION.ago
  end

  # Helper methods
  def full_name
    "#{first_name} #{last_name}"
  end

  # Password reset token generation
  def generate_password_reset_token!
    self.password_reset_token = SecureRandom.urlsafe_base64
    self.password_reset_sent_at = Time.current
    save!
  end

  def password_reset_expired?
    password_reset_sent_at < 2.hours.ago
  end

  private

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end

  def normalize_phone_number
    return unless phone_number.present?

    # Remove all non-digits except leading +
    digits = phone_number.gsub(/[^\d\+]/, "")

    # US-only support for now - normalize to E.164 format (+1XXXXXXXXXX)
    # International support can be added in the future
    if digits.match?(/\A\d{10}\z/)
      # Exactly 10 digits, assume US number
      self.phone_number = "+1#{digits}"
    elsif digits.start_with?("+1") && digits.length == 12
      # Already has +1 prefix with 10 digits
      self.phone_number = digits
    elsif digits.start_with?("+")
      # Has + but not +1, keep as-is for now (future international support)
      self.phone_number = digits
    else
      # Default to US: add +1 prefix
      self.phone_number = "+1#{digits}"
    end
  end
end
