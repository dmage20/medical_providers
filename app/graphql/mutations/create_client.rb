# frozen_string_literal: true

module Mutations
  class CreateClient < BaseMutation
    description "Create a new client"

    argument :client_type, String, required: false
    argument :first_name, String, required: false
    argument :last_name, String, required: false
    argument :business_name, String, required: false
    argument :email, String, required: false
    argument :phone, String, required: false
    argument :address_line1, String, required: false
    argument :city, String, required: false
    argument :state, String, required: false
    argument :postal_code, String, required: false
    argument :status, String, required: false

    field :client, Types::ClientType, null: true
    field :errors, [String], null: false

    def resolve(**args)
      client = Client.new(args)
      if client.save
        {
          client: client,
          errors: []
        }
      else
        {
          client: nil,
          errors: client.errors.full_messages
        }
      end
    end
  end
end
