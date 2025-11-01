# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    # Client mutations
    field :create_client, mutation: Mutations::CreateClient

    # Insurance Policy mutations
    field :create_insurance_policy, mutation: Mutations::CreateInsurancePolicy

    # Lead mutations
    field :create_lead, mutation: Mutations::CreateLead
  end
end
