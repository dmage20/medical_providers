class City < ApplicationRecord
  # Associations
  belongs_to :state
  has_many :addresses, dependent: :restrict_with_error
  has_many :providers, through: :addresses

  # Validations
  validates :name, presence: true
  validates :name, uniqueness: { scope: :state_id }

  # Scopes
  scope :in_state, ->(state_code) {
    joins(:state).where(states: { code: state_code })
  }

  def full_name
    "#{name}, #{state.code}"
  end
end
