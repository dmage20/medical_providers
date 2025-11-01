# frozen_string_literal: true

module Types
  class CommissionType < Types::BaseObject
    description "A broker commission"

    field :id, ID, null: false
    field :agent_name, String, null: true
    field :commission_type, String, null: true
    field :commission_rate, Float, null: true
    field :commission_amount, Float, null: true
    field :payment_date, GraphQL::Types::ISO8601Date, null: true
    field :period_start, GraphQL::Types::ISO8601Date, null: true
    field :period_end, GraphQL::Types::ISO8601Date, null: true
    field :status, String, null: true
    field :notes, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    
    field :insurance_policy, Types::InsurancePolicyType, null: true
  end
end
