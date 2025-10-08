class Endpoint < ApplicationRecord
  belongs_to :provider

  validates :endpoint_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp }

  scope :fhir, -> { where(endpoint_type: "FHIR") }
  scope :direct, -> { where(endpoint_type: "DIRECT") }
end
