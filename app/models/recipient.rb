class Recipient < ApplicationRecord
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true

  before_validation :set_default_name, on: :create

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }

  private

  def set_default_name
    self.name = email.split("@").first if name.blank? && email.present?
  end
end
