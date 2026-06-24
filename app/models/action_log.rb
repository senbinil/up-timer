class ActionLog < ApplicationRecord
  belongs_to :account, optional: true

  validates :action, presence: true
  validates :record_type, presence: true
  validates :record_id, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_record, ->(type, id) { where(record_type: type, record_id: id) }

  def self.log(action:, record:, account: nil, metadata: {})
    create!(
      action: action,
      record_type: record.class.name,
      record_id: record.id,
      account: account,
      metadata: metadata
    )
  end
end
