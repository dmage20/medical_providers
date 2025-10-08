class State < ApplicationRecord
  # Associations
  has_many :cities, dependent: :restrict_with_error
  has_many :addresses, dependent: :restrict_with_error
  has_many :providers, through: :addresses
  has_many :provider_taxonomies, foreign_key: :license_state_id, dependent: :restrict_with_error

  # Validations
  validates :code, presence: true, uniqueness: true, length: { is: 2 }
  validates :name, presence: true

  # Scopes
  scope :with_providers, -> { joins(:providers).distinct }

  def to_s
    code
  end
end
