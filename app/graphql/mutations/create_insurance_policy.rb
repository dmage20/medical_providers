# frozen_string_literal: true

module Mutations
  class CreateInsurancePolicy < BaseMutation
    description "Create a new insurance policy"

    argument :client_id, ID, required: true
    argument :insurance_carrier_id, ID, required: true
    argument :policy_number, String, required: false
    argument :policy_type, String, required: false
    argument :effective_date, GraphQL::Types::ISO8601Date, required: false
    argument :expiration_date, GraphQL::Types::ISO8601Date, required: false
    argument :premium_amount, Float, required: false
    argument :coverage_amount, Float, required: false
    argument :status, String, required: false

    field :insurance_policy, Types::InsurancePolicyType, null: true
    field :errors, [String], null: false

    def resolve(**args)
      policy = InsurancePolicy.new(args)
      if policy.save
        {
          insurance_policy: policy,
          errors: []
        }
      else
        {
          insurance_policy: nil,
          errors: policy.errors.full_messages
        }
      end
    end
  end
end
