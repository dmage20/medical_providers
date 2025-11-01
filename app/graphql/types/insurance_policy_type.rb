# frozen_string_literal: true

module Types
  class InsurancePolicyType < Types::BaseObject
    description "An insurance policy"

    field :id, ID, null: false
    field :policy_number, String, null: true
    field :policy_type, String, null: true
    field :effective_date, GraphQL::Types::ISO8601Date, null: true
    field :expiration_date, GraphQL::Types::ISO8601Date, null: true
    field :premium_amount, Float, null: true
    field :premium_frequency, String, null: true
    field :coverage_amount, Float, null: true
    field :deductible, Float, null: true
    field :status, String, null: true
    field :assigned_agent, String, null: true
    field :notes, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    
    field :client, Types::ClientType, null: true
    field :insurance_carrier, Types::InsuranceCarrierType, null: true
  end
end
