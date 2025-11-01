# frozen_string_literal: true

module Types
  class ClaimType < Types::BaseObject
    description "An insurance claim"

    field :id, ID, null: false
    field :claim_number, String, null: true
    field :claim_date, GraphQL::Types::ISO8601Date, null: true
    field :claim_type, String, null: true
    field :claim_amount, Float, null: true
    field :settlement_amount, Float, null: true
    field :status, String, null: true
    field :filed_date, GraphQL::Types::ISO8601Date, null: true
    field :settlement_date, GraphQL::Types::ISO8601Date, null: true
    field :description, String, null: true
    field :notes, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    
    field :insurance_policy, Types::InsurancePolicyType, null: true
    field :client, Types::ClientType, null: true
  end
end
