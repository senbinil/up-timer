class Account < ApplicationRecord
  include Rodauth::Rails.model
  enum :status, { unverified: 1, verified: 2, closed: 3 }

  ROLES = %w[viewer collaborator admin].freeze

  has_one :user_preference, dependent: :destroy

  before_create :set_status_token
  after_create :build_default_preference

  validates :role, inclusion: { in: ROLES }

  def admin?
    role == "admin"
  end

  def collaborator?
    %w[collaborator admin].include?(role)
  end

  def preference
    user_preference || create_user_preference!
  end

  private

  def set_status_token
    self.status_token = SecureRandom.urlsafe_base64(24)
  end

  def build_default_preference
    create_user_preference!
  end
end
