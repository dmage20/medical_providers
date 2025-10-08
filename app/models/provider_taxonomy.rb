class ProviderTaxonomy < ApplicationRecord
  # Associations
  belongs_to :provider
  belongs_to :taxonomy
  belongs_to :license_state, class_name: "State", optional: true

  # Validations
  validates :provider_id, uniqueness: { scope: :taxonomy_id }
  validate :only_one_primary_per_provider, if: :is_primary?

  # Scopes
  scope :primary, -> { where(is_primary: true) }
  scope :secondary, -> { where(is_primary: false) }

  private

  def only_one_primary_per_provider
    if provider.provider_taxonomies.where(is_primary: true).where.not(id: id).exists?
      errors.add(:is_primary, "provider can only have one primary taxonomy")
    end
  end
end
