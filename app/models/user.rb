class User < ApplicationRecord
  devise :database_authenticatable, :validatable

  # Associations
  has_many :workouts, dependent: :destroy
  has_one :user_preference, dependent: :destroy
  has_many :weekly_feedbacks, dependent: :destroy

  # Delegations
  delegate :primary_goal, :training_days_per_week, to: :user_preference, allow_nil: true

  # Validations
  validates :email,
    presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :first_name, :last_name, presence: true

  # Normalize email to lowercase before saving
  before_save :normalize_email

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
end
