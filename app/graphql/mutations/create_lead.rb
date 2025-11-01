# frozen_string_literal: true

module Mutations
  class CreateLead < BaseMutation
    description "Create a new lead"

    argument :source, String, required: false
    argument :first_name, String, required: false
    argument :last_name, String, required: false
    argument :business_name, String, required: false
    argument :email, String, required: false
    argument :phone, String, required: false
    argument :interest_type, String, required: false
    argument :status, String, required: false

    field :lead, Types::LeadType, null: true
    field :errors, [String], null: false

    def resolve(**args)
      lead = Lead.new(args)
      if lead.save
        {
          lead: lead,
          errors: []
        }
      else
        {
          lead: nil,
          errors: lead.errors.full_messages
        }
      end
    end
  end
end
